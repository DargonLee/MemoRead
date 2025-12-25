//
//  MemoReadApp.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/24.
//

import SwiftUI
import SwiftData

#if os(macOS)
import AppKit

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置菜单栏应用策略（不显示 Dock 图标）
        NSApp.setActivationPolicy(.accessory)
    }
}
#endif

@main
struct MemoReadApp: App {
    @State private var viewModel = HomeViewModel()
    @AppStorage("app_appearance") private var selectedAppearance: Appearance = .automatic
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    init() {
        // 1. 启动同步服务
        MultipeerSyncService.shared.start()
        
        // 2. 立即设置全局同步处理器
        // 使用 mainContext 确保同步的数据能立即在 UI 上反映出来
        if let container = ModelContainerService.shared.modelContainer {
            let context = container.mainContext
            MultipeerSyncService.shared.setupSyncHandlers(modelContext: context)
        }
    }

    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            HomeView()
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(viewModel)
        }
        .modelContainer(ModelContainerService.shared.modelContainer ?? {
            return try! ModelContainer(for: ReadingCardModel.self)
        }())
        #elseif os(macOS)
        // macOS 使用菜单栏模式
        MenuBarExtra {
            if let container = ModelContainerService.shared.modelContainer {
                MenuBarContentView()
                    .preferredColorScheme(selectedAppearance.colorScheme)
                    .environment(viewModel)
                    .modelContext(container.mainContext)
                    .frame(minWidth: 600, minHeight: 700)
            } else {
                Text("Error: Model Container not available")
            }
        } label: {
            Image(systemName: "book.fill")
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}

#if os(macOS)
// MARK: - Menu Bar Content View
private struct MenuBarContentView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HomeView_macOS()
            .onAppear {
                // ⚠️ 关键修复：用窗口的 modelContext 重新设置同步处理器
                // 这样数据会保存到窗口正在使用的 context 中
                MultipeerSyncService.shared.setupSyncHandlers(modelContext: modelContext)
                
                // 窗口显示时，设置 UI 相关的回调（如通知显示）
                configureSyncCallbacks()
            }
    }
    
    // MARK: - Sync Callbacks
    private func configureSyncCallbacks() {
        let service = MultipeerSyncService.shared
        
        service.onPeerConnected = { [modelContext] peer in
            DispatchQueue.main.async {
                // macOS 端连接后自动同步待同步数据
                service.syncPendingCards(modelContext: modelContext)
                service.syncPendingDeletions(modelContext: modelContext)
            }
        }
        
        service.onSyncCompleted = { success, error in
            DispatchQueue.main.async {
                if success {
                    // 同步成功，发送本地通知
                    NotificationManager.shared.sendInstantNotification(
                        title: "✓ 数据同步完成",
                        body: "所有数据已成功同步到已连接的设备",
                        sound: true
                    )
                } else if error != nil {
                    // 同步失败，发送错误通知
                    NotificationManager.shared.sendInstantNotification(
                        title: "⚠️ 同步失败",
                        body: "数据同步时出现问题，请检查网络连接后重试",
                        sound: false
                    )
                }
            }
        }
    }
}
#endif

