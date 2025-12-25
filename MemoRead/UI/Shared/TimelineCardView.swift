//
//  TimelineCardView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

struct TimelineCardView: View {
    @Environment(\.modelContext) private var modelContext
    let item: ReadingCardModel
    let isLast: Bool
    @State private var isSynced: Bool
    @State private var showSummarySheet = false
    @State private var summaryText: String = ""
    @State private var isGeneratingSummary = false
    private let type: ReadingCardModel.ReadingCardType
    
    private var tagText: String {
        if let tag = item.extractedTag { return "#\(tag)" }
        return "#\(type.name)"
    }
    
    // MARK: - Initialization
    init(item: ReadingCardModel, isLast: Bool = false) {
        self.item = item
        self.isLast = isLast
        _isSynced = State(initialValue: item.isSynced)
        self.type = ReadingCardModel.ReadingCardType(rawValue: item.type)!
    }
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            timelineIndicator
            cardSection
        }
        .padding(.horizontal, 16)
        .background(TimelineStyle.listBackground)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                handleDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showSummarySheet) {
            SummarySheetView(
                content: item.content,
                summary: $summaryText,
                isGenerating: $isGeneratingSummary
            )
        }
        .onChange(of: item.isSynced) { _, newValue in
            isSynced = newValue
        }
    }
    
    // MARK: - Timeline Indicator
    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(TimelineStyle.accent)
                .frame(width: 15, height: 15)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            if !isLast {
                Rectangle()
                    .fill(TimelineStyle.line)
                    .frame(width: 2)
            } else {
                Spacer()
            }
        }
    }

    // MARK: - Card Section
    private var cardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            
            VStack(alignment: .leading, spacing: 16) {
                ReadingCardContentView(item: item)
                footerView
            }
            .padding(16)
            .background(TimelineStyle.cardBackground)
            .cornerRadius(20)
            .shadow(
                color: TimelineStyle.cardShadow.opacity(0.12),
                radius: 10,
                x: 0,
                y: 4
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(item.createdAt.timeAgoDisplay())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 10) {
                // 类型图标 (如果是链接或图片)
                if type != ReadingCardModel.ReadingCardType.text {
                    Image(systemName: type.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                // 同步/完成状态
                if isSynced {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green.opacity(0.8))
                } else {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        HStack(alignment: .center) {
            Text(tagText)
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 18) {
                AISummaryButton(action: handleAISummary)
                
                IconButton(systemName: "doc.on.doc") {
                    item.content.copyToClipboard()
                }
                
                IconButton(systemName: "square.and.arrow.up") {
                    handleShare()
                }
            }
        }
    }
    
    // MARK: - Actions
    private func handleShare() {
        #if os(iOS)
        let activityVC = UIActivityViewController(
            activityItems: [item.content],
            applicationActivities: nil
        )
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
    
    private func handleAISummary() {
        isGeneratingSummary = true
        showSummarySheet = true
        
        AISummaryService.shared.generateSummary(for: item.content) { result in
            DispatchQueue.main.async {
                isGeneratingSummary = false
                switch result {
                case .success(let summary):
                    summaryText = summary
                case .failure(let error):
                    summaryText = "生成总结时出错: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handleDelete() {
        #if os(iOS)
        let service = MultipeerSyncService.shared
        
        // 检查是否有连接的设备
        if service.hasConnectedPeers {
            // 有连接，立即同步删除
            let syncSuccess = service.syncCardDeletion(item.id)
            if syncSuccess {
                // 同步成功，直接删除
                modelContext.delete(item)
            } else {
                // 同步失败，标记为待删除
                item.pendingDeletion = true
            }
        } else {
            // 没有连接，标记为待删除，等待连接后同步
            item.pendingDeletion = true
        }
        #else
        // macOS 直接删除
        modelContext.delete(item)
        #endif
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete card: \(error.localizedDescription)")
        }
    }
}

// MARK: - Style & Layout
private enum TimelineStyle {
    static let accent = Color.blue
    static let line = Color.blue.opacity(0.3)
    static let cardShadow = Color.black
    
    static var cardBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return .white
        #endif
    }
    
    static var listBackground: Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color.clear
        #endif
    }
}

#Preview {
    VStack(spacing: 0) {
        TimelineCardView(item: ReadingCardModel.sampleCards()[0], isLast: false)
        TimelineCardView(item: ReadingCardModel.sampleCards()[1], isLast: false)
        TimelineCardView(item: ReadingCardModel.sampleCards()[2], isLast: true)
    }
}

