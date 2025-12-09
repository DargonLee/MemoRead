//
//  MultipeerSyncService.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import Foundation
import MultipeerConnectivity
import SwiftData
import OSLog

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Sync Message Protocol
struct SyncMessage: Codable {
    let type: MessageType
    let cardData: CardData?
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case cardCreated
        case cardUpdated
        case cardDeleted
        case syncRequest
        case syncResponse
    }
}

struct CardData: Codable {
    let id: UUID
    let content: String
    let type: Int
    let createdAt: Date
    let reminderAt: Date?
    let completedAt: Date?
    let isCompleted: Bool
}

// MARK: - Multipeer Sync Service
class MultipeerSyncService: NSObject {
    static let shared = MultipeerSyncService()
    
    // MARK: - Properties
    private let serviceType = "memoread-sync"
    private let myPeerId: MCPeerID
    private var session: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    
    // MARK: - Callbacks
    var onConnectedDevicesChanged: (([String]) -> Void)?
    var onSyncCompleted: ((Bool, String?) -> Void)?
    var onCardReceived: ((CardData) -> Void)?
    
    private var connectedPeers: Set<MCPeerID> = [] {
        didSet {
            let deviceNames = connectedPeers.map { $0.displayName }
            onConnectedDevicesChanged?(deviceNames)
        }
    }
    
    // MARK: - Logger
    let logger = Logger(subsystem: "io.memoread.app", category: "MultipeerSync")
    
    // MARK: - Initialization
    private override init() {
        // 根据平台设置不同的显示名称
        #if os(iOS)
        let displayName = UIDevice.current.name
        #elseif os(macOS)
        let displayName = Host.current().name ?? "Mac"
        #else
        let displayName = "Device"
        #endif
        
        self.myPeerId = MCPeerID(displayName: displayName)
        super.init()
        
        setupSession()
    }
    
    // MARK: - Setup
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
    }
    
    // MARK: - Service Control
    func startAdvertising() {
        guard serviceAdvertiser == nil else { return }
        
        let discoveryInfo = ["version": "1.0"]
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
        
        logger.info("开始广播服务")
    }
    
    func stopAdvertising() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = nil
        logger.info("停止广播服务")
    }
    
    func startBrowsing() {
        guard serviceBrowser == nil else { return }
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
        
        logger.info("开始浏览服务")
    }
    
    func stopBrowsing() {
        serviceBrowser?.stopBrowsingForPeers()
        serviceBrowser = nil
        logger.info("停止浏览服务")
    }
    
    func start() {
        #if os(iOS)
        // iOS 作为浏览器，主动搜索 Mac
        startBrowsing()
        #elseif os(macOS)
        // Mac 作为广告者，等待 iOS 连接
        startAdvertising()
        #endif
    }
    
    func stop() {
        stopAdvertising()
        stopBrowsing()
        session?.disconnect()
    }
    
    // MARK: - Data Sync
    func syncCard(_ card: ReadingCardModel, type: SyncMessage.MessageType) {
        guard let session = session, !connectedPeers.isEmpty else {
            logger.warning("没有连接的设备，无法同步")
            return
        }
        
        let cardData = CardData(
            id: card.id,
            content: card.content,
            type: card.type,
            createdAt: card.createdAt,
            reminderAt: card.reminderAt,
            completedAt: card.completedAt,
            isCompleted: card.isCompleted
        )
        
        let message = SyncMessage(
            type: type,
            cardData: cardData,
            timestamp: Date()
        )
        
        sendMessage(message)
    }
    
    private func sendMessage(_ message: SyncMessage) {
        guard let session = session,
              let data = try? JSONEncoder().encode(message) else {
            logger.error("编码消息失败")
            return
        }
        
        do {
            try session.send(data, toPeers: Array(connectedPeers), with: .reliable)
            logger.info("成功发送消息: \(message.type.rawValue)")
        } catch {
            logger.error("发送消息失败: \(error.localizedDescription)")
            onSyncCompleted?(false, error.localizedDescription)
        }
    }
    
    private func handleReceivedMessage(_ data: Data, from peer: MCPeerID) {
        guard let message = try? JSONDecoder().decode(SyncMessage.self, from: data) else {
            logger.error("解码消息失败")
            return
        }
        
        logger.info("收到消息: \(message.type.rawValue) from \(peer.displayName)")
        
        switch message.type {
        case .cardCreated, .cardUpdated:
            if let cardData = message.cardData {
                handleCardSync(cardData, isUpdate: message.type == .cardUpdated)
            }
        case .cardDeleted:
            if let cardData = message.cardData {
                handleCardDeletion(cardData.id)
            }
        case .syncRequest:
            // 处理同步请求
            handleSyncRequest()
        case .syncResponse:
            // 处理同步响应
            break
        }
    }
    
    private func handleCardSync(_ cardData: CardData, isUpdate: Bool) {
        DispatchQueue.main.async {
            // 通过回调通知外部处理数据同步
            self.onCardReceived?(cardData)
            self.logger.info("收到卡片同步: \(cardData.id)")
        }
    }
    
    private func handleCardDeletion(_ cardId: UUID) {
        DispatchQueue.main.async {
            self.logger.info("收到删除请求: \(cardId)")
            // 删除操作通过回调处理，发送包含 cardId 的 CardData
            let cardData = CardData(
                id: cardId,
                content: "",
                type: 0,
                createdAt: Date(),
                reminderAt: nil,
                completedAt: nil,
                isCompleted: false
            )
            // 可以通过特殊标记来标识删除操作
            self.onCardReceived?(cardData)
        }
    }
    
    private func handleSyncRequest() {
        // 实现全量同步请求
        logger.info("收到同步请求")
    }
    
    // MARK: - Helper Methods
    func syncCardToPeers(_ card: ReadingCardModel) {
        syncCard(card, type: .cardCreated)
    }
    
    func syncCardUpdate(_ card: ReadingCardModel) {
        syncCard(card, type: .cardUpdated)
    }
    
    func syncCardDeletion(_ cardId: UUID) {
        // 创建一个临时的 CardData 用于删除
        let cardData = CardData(
            id: cardId,
            content: "",
            type: 0,
            createdAt: Date(),
            reminderAt: nil,
            completedAt: nil,
            isCompleted: false
        )
        
        let message = SyncMessage(
            type: .cardDeleted,
            cardData: cardData,
            timestamp: Date()
        )
        
        sendMessage(message)
    }
}

// MARK: - MCSessionDelegate
extension MultipeerSyncService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeers.insert(peerID)
                self.logger.info("设备已连接: \(peerID.displayName)")
            case .connecting:
                self.logger.info("正在连接: \(peerID.displayName)")
            case .notConnected:
                self.connectedPeers.remove(peerID)
                self.logger.info("设备已断开: \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handleReceivedMessage(data, from: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // 流传输暂不实现
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // 资源传输暂不实现
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // 资源传输暂不实现
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerSyncService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("收到连接邀请 from \(peerID.displayName)")
        // 自动接受邀请
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        logger.error("广播失败: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerSyncService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        logger.info("发现设备: \(peerID.displayName)")
        // 自动发送连接邀请
        browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("设备丢失: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        logger.error("浏览失败: \(error.localizedDescription)")
    }
}

