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
    
    var body: some View {
        NavigationStack {
            contentView
                .background(ThemeStyle.listBackground)
                .navigationTitle("MemoRead")
                .toolbar { toolbarItem() }
                .sheet(isPresented: $isSettingPresented) { SettingView() }
                .sheet(isPresented: $isAddCardPresented) { addCardSheet }
                .toast()
                .onAppear {
                    // 仅设置 UI 相关的回调（如弹窗提示）
                    configureSyncCallbacks()
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
    private func configureSyncCallbacks() {
        let service = MultipeerSyncService.shared
        
        service.onPeerConnected = { [modelContext] peer in
            DispatchQueue.main.async {
                ToastManager.shared.show("已连接 \(peer.displayName)", style: .success)
                service.syncPendingCards(modelContext: modelContext)
                service.syncPendingDeletions(modelContext: modelContext)
            }
        }
        
        service.onSyncCompleted = { success, error in
            DispatchQueue.main.async {
                if success {
                    ToastManager.shared.show("同步完成", style: .success)
                } else if let error {
                    ToastManager.shared.show("同步失败：\(error)", style: .error)
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
