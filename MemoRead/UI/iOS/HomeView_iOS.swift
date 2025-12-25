//
//  HomeView_iOS.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

#if os(iOS)
struct HomeView_iOS: View {
    // MARK: - Environment
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var isSettingPresented: Bool = false
    @State private var isAddCardPresented: Bool = false
    @State private var showSyncAlert: Bool = false
    @State private var syncAlertMessage: String = ""
    
    var body: some View {
        NavigationStack {
            contentView
                .background(ThemeStyle.listBackground)
                .navigationTitle("MemoRead")
                .toolbar { toolbarItem() }
                .sheet(isPresented: $isSettingPresented) { SettingView() }
                .sheet(isPresented: $isAddCardPresented) { addCardSheet }
                .alert("同步提示", isPresented: $showSyncAlert) {
                    Button("好的", role: .cancel) { }
                } message: {
                    Text(syncAlertMessage)
                }
                .onAppear {
                    // 设置同步服务回调
                    configureSyncService()
                }
        }
        
    }
    
    // MARK: - Content
    private var contentView: some View {
        ZStack {
            ReadingCardListView(
                searchText: viewModel.searchText,
                sortParameter: viewModel.sortParameter,
                sortOrder: viewModel.sortOrder
            )
            .searchable(text: searchTextBinding, prompt: "Search")
            
            AddButton(addAction: { isAddCardPresented = true })
        }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { viewModel.searchText = $0 }
        )
    }
    
    private var addCardSheet: some View {
        AddCardView()
            .presentationDetents([.medium, .large])
    }
    
    @ToolbarContentBuilder
    private func toolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            settingsButton
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            SortButton()
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            isSettingPresented.toggle()
        }) {
            Image(systemName: "gearshape")
        }
    }

    // MARK: - Sync
    private func configureSyncService() {
        let service = MultipeerSyncService.shared
        service.setupSyncHandlers(modelContext: modelContext)
        configureSyncCallbacks(service: service)
    }
    
    private func configureSyncCallbacks(service: MultipeerSyncService) {
        service.onPeerConnected = { peer in
            DispatchQueue.main.async {
                syncAlertMessage = "已连接 \(peer.displayName)，开始检查未同步数据"
                showSyncAlert = true
                service.syncPendingCards(modelContext: modelContext)
                service.syncPendingDeletions(modelContext: modelContext)
            }
        }
        
        service.onSyncCompleted = { success, error in
            DispatchQueue.main.async {
                if success {
                    syncAlertMessage = "同步完成"
                    showSyncAlert = true
                } else if let error {
                    syncAlertMessage = "同步失败：\(error)"
                    showSyncAlert = true
                }
            }
        }
    }
}

#Preview("English") {
    @Previewable @State var viewModel = HomeViewModel()
    let preview = Preview(ReadingCardModel.self)
    let cards = ReadingCardModel.sampleCards()
    preview.addExamples(cards)
    
    return HomeView_iOS()
            .environment(viewModel)
            .modelContainer(preview.container)
}


//#Preview("Chinese") {
//    @Previewable @State var viewModel = HomeViewModel()
//    let preview = Preview(ReadingCardModel.self)
//    let cards = ReadingCardModel.sampleCards()
//    preview.addExamples(cards)
//    
//    return HomeView_iOS()
//            .environment(viewModel)
//            .modelContainer(preview.container)
//            .environment(\.local, Locale(identifier: "zh-Hans"))
//}
#endif
