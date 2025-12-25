//
//  MultipeerSyncService+Extensions.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import Foundation
import SwiftData
import OSLog

extension MultipeerSyncService {
    // MARK: - ModelContext Integration
    func setupSyncHandlers(modelContext: ModelContext) {
        // 设置接收卡片的回调
        onCardReceived = { [weak self] cardData in
            self?.handleReceivedCard(cardData, in: modelContext)
        }
    }
    
    private func handleReceivedCard(_ cardData: CardData, in modelContext: ModelContext) {
        let resolvedContent = cardData.imageDataBase64 ?? cardData.content

        // 检查是否已存在
        let descriptor = FetchDescriptor<ReadingCardModel>(
            predicate: #Predicate { $0.id == cardData.id }
        )
        
        do {
            let existing = try modelContext.fetch(descriptor)
            
            if let existingCard = existing.first {
                existingCard.content = resolvedContent
                existingCard.type = cardData.type
                existingCard.createdAt = cardData.createdAt
                existingCard.reminderAt = cardData.reminderAt
                existingCard.completedAt = cardData.completedAt
                existingCard.isCompleted = cardData.isCompleted
                existingCard.isSynced = true
                existingCard.lastSyncedAt = cardData.lastSyncedAt ?? Date()
            } else {
                // 创建新卡片
                let newCard = ReadingCardModel(
                    id: cardData.id,
                    content: resolvedContent,
                    createdAt: cardData.createdAt,
                    reminderAt: cardData.reminderAt ?? Date.distantPast
                )
                newCard.type = cardData.type
                newCard.completedAt = cardData.completedAt
                newCard.isCompleted = cardData.isCompleted
                newCard.isSynced = true
                newCard.lastSyncedAt = cardData.lastSyncedAt ?? Date()
                modelContext.insert(newCard)
            }
            
            try modelContext.save()
            logger.info("成功同步卡片: \(cardData.id)")
            onSyncCompleted?(true, nil)
        } catch {
            logger.error("保存同步数据失败: \(error.localizedDescription)")
            onSyncCompleted?(false, error.localizedDescription)
        }
    }
    
    func handleCardDeletion(_ cardId: UUID, in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReadingCardModel>(
            predicate: #Predicate { $0.id == cardId }
        )
        
        do {
            if let card = try modelContext.fetch(descriptor).first {
                modelContext.delete(card)
                try modelContext.save()
                logger.info("成功删除卡片: \(cardId)")
            }
        } catch {
            logger.error("删除卡片失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Bulk Sync Helpers
    func syncPendingCards(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ReadingCardModel>(
            predicate: #Predicate { $0.isSynced == false }
        )

        do {
            let pending = try modelContext.fetch(descriptor)
            pending.forEach { card in
                MultipeerSyncService.shared.syncCardToPeers(card, modelContext: modelContext)
            }
        } catch {
            logger.error("拉取未同步数据失败: \(error.localizedDescription)")
        }
    }
}

