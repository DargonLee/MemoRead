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
    @Environment(\.modelContext) private var modelContxt
    
    // MARK: - State
    @State private var isSettingPresented: Bool = false
    @State private var isAddCardPresented: Bool = false
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            ZStack {
                VStack {
                    ReadingCardListView(
                        searchText: viewModel.searchText,
                        sortParameter: viewModel.sortParameter,
                        sortOrder: viewModel.sortOrder
                    )
                        .searchable(text: $viewModel.searchText, prompt: "搜索")
                        .navigationTitle("MemoRead")
                        .toolbar {
                            toolbarItem()
                        }
                }
                .sheet(isPresented: $isSettingPresented) {
                    SettingView()
                }
                .sheet(isPresented: $isAddCardPresented) {
                    AddCardView()
                        .presentationDetents([.medium])
                }
                AddButton(addAction: {
                    isAddCardPresented = true
                })
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            settingsButton
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            SortButton( )
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            isSettingPresented.toggle()
        }) {
            Image(systemName: "gearshape")
        }
    }
}

#Preview {
    @Previewable @State var viewModel = HomeViewModel()
    let preview = Preview(ReadingCardModel.self)
    let cards = ReadingCardModel.sampleCards()
    preview.addExamples(cards)
    
    return HomeView_iOS()
            .environment(viewModel)
            .modelContainer(preview.container)
}
#endif
