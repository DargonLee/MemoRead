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
import Combine

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
    let imageDataBase64: String?
    let isSynced: Bool
    let lastSyncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, content, type, createdAt, reminderAt, completedAt, isCompleted, imageDataBase64, isSynced, lastSyncedAt
    }

    init(
        id: UUID,
        content: String,
        type: Int,
        createdAt: Date,
        reminderAt: Date?,
        completedAt: Date?,
        isCompleted: Bool,
        imageDataBase64: String? = nil,
        isSynced: Bool = true,
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.reminderAt = reminderAt
        self.completedAt = completedAt
        self.isCompleted = isCompleted
        self.imageDataBase64 = imageDataBase64
        self.isSynced = isSynced
        self.lastSyncedAt = lastSyncedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        type = try container.decode(Int.self, forKey: .type)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        reminderAt = try container.decodeIfPresent(Date.self, forKey: .reminderAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        imageDataBase64 = try container.decodeIfPresent(String.self, forKey: .imageDataBase64)
        isSynced = try container.decodeIfPresent(Bool.self, forKey: .isSynced) ?? true
        lastSyncedAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncedAt)
    }
}

// MARK: - Multipeer Sync Service
class MultipeerSyncService: NSObject, ObservableObject {
    static let shared = MultipeerSyncService()
    
    // MARK: - Published Properties
    @Published var isSearching: Bool = false
    @Published var isConnected: Bool = false
    @Published var connectedDeviceNames: [String] = []
    
    // MARK: - Properties
    private let serviceType = "memoread-sync"
    private let myPeerId: MCPeerID
    private var session: MCSession?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var invitingPeers: Set<MCPeerID> = []
    private var isResettingSession = false
    private var connectionCheckTimer: Timer?
    
    // MARK: - Callbacks
    var onConnectedDevicesChanged: (([String]) -> Void)?
    var onSyncCompleted: ((Bool, String?) -> Void)?
    var onCardReceived: ((CardData) -> Void)?
    var onPeerConnected: ((MCPeerID) -> Void)?
    
    private var connectedPeers: Set<MCPeerID> = [] {
        didSet {
            let deviceNames = connectedPeers.map { $0.displayName }
            DispatchQueue.main.async {
                self.isConnected = !self.connectedPeers.isEmpty
                self.connectedDeviceNames = deviceNames
            }
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
    
    // MARK: - Peer Validation
    private func shouldAcceptPeer(_ peerID: MCPeerID) -> Bool {
        let peerName = peerID.displayName.lowercased()
        
        #if os(iOS)
        // iOS 端：只接受包含 "mac" 的设备名，排除 iPhone/iPad 等
        return peerName.contains("mac") || peerName.contains("macbook")
        #elseif os(macOS)
        // Mac 端：只接受 iOS 设备（排除其他 Mac）
        return !peerName.contains("mac") && !peerName.contains("macbook")
        #else
        return true
        #endif
    }
    
    // MARK: - Setup
    private func setupSession() {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .optional)
        session?.delegate = self
    }

    private func makeCardData(from card: ReadingCardModel) -> CardData {
        let imageBase64 = card.type == ReadingCardModel.ReadingCardType.image.rawValue ? card.content : nil
        return CardData(
            id: card.id,
            content: card.content,
            type: card.type,
            createdAt: card.createdAt,
            reminderAt: card.reminderAt,
            completedAt: card.completedAt,
            isCompleted: card.isCompleted,
            imageDataBase64: imageBase64,
            isSynced: true,
            lastSyncedAt: Date()
        )
    }

    private func ensureSession() -> MCSession {
        if let session {
            return session
        }
        setupSession()
        return session!
    }

    private func resetSessionIfNeeded() {
        // 避免同时触发多个重建
        guard !isResettingSession else { return }
        isResettingSession = true

        // 断开并重建新的 session，防止握手卡死
        session?.disconnect()
        setupSession()

        invitingPeers.removeAll()
        connectedPeers.removeAll()

        // 继续保持广播/浏览
        #if os(iOS)
        startBrowsing()
        #elseif os(macOS)
        startAdvertising()
        #endif

        isResettingSession = false
    }
    
    // MARK: - Service Control
    func startAdvertising() {
        guard serviceAdvertiser == nil else { return }
        
        let discoveryInfo = [
            "version": "1.0",
            "platform": "macOS"
        ]
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
        
        DispatchQueue.main.async {
            self.isSearching = true
        }
        logger.info("开始广播服务")
    }
    
    func stopAdvertising() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = nil
        DispatchQueue.main.async {
            self.isSearching = false
        }
        logger.info("停止广播服务")
    }
    
    func startBrowsing() {
        guard serviceBrowser == nil else { return }
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
        
        DispatchQueue.main.async {
            self.isSearching = true
        }
        logger.info("开始浏览服务")
    }
    
    func stopBrowsing() {
        serviceBrowser?.stopBrowsingForPeers()
        serviceBrowser = nil
        DispatchQueue.main.async {
            self.isSearching = false
        }
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
        
        // 启动定时检查连接状态
        startConnectionCheck()
    }
    
    func stop() {
        stopAdvertising()
        stopBrowsing()
        stopConnectionCheck()
        session?.disconnect()
        session = nil
        invitingPeers.removeAll()
        connectedPeers.removeAll()
    }
    
    // MARK: - Connection Check
    private func startConnectionCheck() {
        stopConnectionCheck()
        // 改为 2 秒检查一次，让断开检测更快
        connectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkConnectionStatus()
        }
    }
    
    private func stopConnectionCheck() {
        connectionCheckTimer?.invalidate()
        connectionCheckTimer = nil
    }
    
    private func checkConnectionStatus() {
        guard let session = session else { return }
        
        DispatchQueue.main.async {
            // 获取 session 实际连接的设备，并过滤只保留正确类型的设备
            let actualConnectedPeers = Set(session.connectedPeers.filter { self.shouldAcceptPeer($0) })
            
            // 如果我们记录的连接和实际连接不一致，同步状态
            if actualConnectedPeers != self.connectedPeers {
                // 断开不匹配的设备
                let shouldNotConnect = Set(session.connectedPeers).subtracting(actualConnectedPeers)
                shouldNotConnect.forEach { peer in
                    self.logger.info("过滤并断开设备: \(peer.displayName)")
                    session.cancelConnectPeer(peer)
                }
                
                // 同步状态
                self.connectedPeers = actualConnectedPeers
            }
        }
    }
    
    // MARK: - Data Sync
    @discardableResult
    func syncCard(_ card: ReadingCardModel, type: SyncMessage.MessageType) -> Bool {
        guard session != nil, !connectedPeers.isEmpty else {
            logger.warning("没有连接的设备，无法同步")
            return false
        }
        
        let cardData = makeCardData(from: card)
        
        let message = SyncMessage(
            type: type,
            cardData: cardData,
            timestamp: Date()
        )
        
        return sendMessage(message)
    }
    
    @discardableResult
    private func sendMessage(_ message: SyncMessage) -> Bool {
        guard let session = session,
              let data = try? JSONEncoder().encode(message) else {
            logger.error("编码消息失败")
            return false
        }
        
        do {
            try session.send(data, toPeers: Array(connectedPeers), with: .reliable)
            logger.info("成功发送消息: \(message.type.rawValue)")
            onSyncCompleted?(true, nil)
            return true
        } catch {
            logger.error("发送消息失败: \(error.localizedDescription)")
            // 发送失败时立即检查连接状态
            checkConnectionStatus()
            onSyncCompleted?(false, error.localizedDescription)
            return false
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

        onSyncCompleted?(true, nil)
    }
    
    private func handleCardSync(_ cardData: CardData, isUpdate: Bool) {
        
        DispatchQueue.main.async {
            self.logger.info("收到卡片同步: \(cardData.id)")
            self.onCardReceived?(cardData)
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
    func syncCardToPeers(_ card: ReadingCardModel, modelContext: ModelContext? = nil) {
        let success = syncCard(card, type: .cardCreated)
        updateSyncState(for: card, success: success, modelContext: modelContext)
    }
    
    func syncCardUpdate(_ card: ReadingCardModel, modelContext: ModelContext? = nil) {
        let success = syncCard(card, type: .cardUpdated)
        updateSyncState(for: card, success: success, modelContext: modelContext)
    }
    
    /// 检查是否有连接的设备
    var hasConnectedPeers: Bool {
        return session != nil && !connectedPeers.isEmpty
    }
    
    func syncCardDeletion(_ cardId: UUID) -> Bool {
        guard hasConnectedPeers else {
            logger.warning("没有连接的设备，删除操作将延迟到连接后同步")
            return false
        }
        
        // 创建一个临时的 CardData 用于删除
        let cardData = CardData(
            id: cardId,
            content: "",
            type: 0,
            createdAt: Date(),
            reminderAt: nil,
            completedAt: nil,
            isCompleted: false,
            imageDataBase64: nil,
            isSynced: true,
            lastSyncedAt: Date()
        )
        
        let message = SyncMessage(
            type: .cardDeleted,
            cardData: cardData,
            timestamp: Date()
        )
        
        return sendMessage(message)
    }
    
    /// 同步所有待删除的卡片
    func syncPendingDeletions(modelContext: ModelContext) {
        guard hasConnectedPeers else {
            logger.info("没有连接的设备，跳过待删除同步")
            return
        }
        
        let descriptor = FetchDescriptor<ReadingCardModel>(
            predicate: #Predicate { $0.pendingDeletion == true }
        )
        
        do {
            let pendingCards = try modelContext.fetch(descriptor)
            logger.info("开始同步 \(pendingCards.count) 个待删除的卡片")
            
            for card in pendingCards {
                let success = syncCardDeletion(card.id)
                if success {
                    // 同步成功后，清除待删除标记并从数据库删除
                    card.pendingDeletion = false
                    modelContext.delete(card)
                    logger.info("成功同步删除卡片: \(card.id)")
                }
            }
            
            try modelContext.save()
        } catch {
            logger.error("同步待删除卡片失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync State Helpers
    private func updateSyncState(for card: ReadingCardModel, success: Bool, modelContext: ModelContext?) {
        guard let modelContext else { return }
        card.isSynced = success
        card.lastSyncedAt = success ? Date() : card.lastSyncedAt
        do {
            try modelContext.save()
        } catch {
            logger.error("保存同步状态失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerSyncService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.invitingPeers.remove(peerID)
                
                // 再次验证设备类型
                if self.shouldAcceptPeer(peerID) {
                    self.connectedPeers.insert(peerID)
                    self.logger.info("设备已连接: \(peerID.displayName)")
                    self.onPeerConnected?(peerID)
                } else {
                    self.logger.info("设备类型不匹配，断开连接: \(peerID.displayName)")
                    self.session?.cancelConnectPeer(peerID)
                }
                
            case .connecting:
                self.logger.info("正在连接: \(peerID.displayName)")
            case .notConnected:
                self.invitingPeers.remove(peerID)
                self.connectedPeers.remove(peerID)
                self.logger.info("设备已断开: \(peerID.displayName)")
                
                // 如果所有连接都断开，重建 session 以清除异常状态
                if self.connectedPeers.isEmpty && self.session?.connectedPeers.isEmpty ?? true {
                    self.logger.info("重建会话以恢复连接能力")
                    self.resetSessionIfNeeded()
                }
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
        // 检查是否应该接受该设备
        if shouldAcceptPeer(peerID) {
            logger.info("接受连接邀请: \(peerID.displayName)")
            invitationHandler(true, ensureSession())
        } else {
            logger.info("拒绝连接邀请: \(peerID.displayName)")
            invitationHandler(false, nil)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        logger.error("广播失败: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerSyncService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        #if os(iOS)
        // iOS 只连接 macOS 设备
        guard let platform = info?["platform"], platform == "macOS" else {
            return
        }
        #endif
        
        // 避免重复邀请或邀请已连接的设备
        guard !invitingPeers.contains(peerID) && !connectedPeers.contains(peerID) else {
            return
        }
        
        invitingPeers.insert(peerID)
        logger.info("发现并邀请设备: \(peerID.displayName)")
        browser.invitePeer(peerID, to: ensureSession(), withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("设备丢失: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        logger.error("浏览失败: \(error.localizedDescription)")
    }
}

