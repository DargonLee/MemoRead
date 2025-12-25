//
//  MemoReadApp.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/24.
//

import SwiftUI

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

    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            HomeView()
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(viewModel)
                .onAppear {
                    MultipeerSyncService.shared.start()
                }
        }
        .modelContainer(for: ReadingCardModel.self)
        #elseif os(macOS)
        // macOS 使用菜单栏模式
        MenuBarExtra {
            MenuBarContentView()
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(viewModel)
                .frame(minWidth: 600, minHeight: 700)
                .onAppear {
                    MultipeerSyncService.shared.start()
                }
        } label: {
            Image(systemName: "book.fill")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(for: ReadingCardModel.self)
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
                // 设置同步服务回调
                MultipeerSyncService.shared.setupSyncHandlers(modelContext: modelContext)
                configureSyncCallbacks()
            }
    }
    
    // MARK: - Sync Callbacks
    private func configureSyncCallbacks() {
        let service = MultipeerSyncService.shared
        
        service.onPeerConnected = { peer in
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

