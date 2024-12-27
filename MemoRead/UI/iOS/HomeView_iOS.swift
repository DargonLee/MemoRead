//
//  HomeView_iOS.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

#if os(iOS)
struct HomeView_iOS: View {
    // MARK: - State
    @State private var selectedFilter: ReadingCardSortType = .all
    @State private var selectedSort: ReadingCardSortOption = .timeAscending
    @State private var searchText: String = ""
    @State private var isSettingPresented: Bool = false
    @State private var isAddCardPresented: Bool = false
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    ReadingCardListView(readingCards: ReadingCardModel.sampleData())
                        .searchable(text: $searchText, prompt: "搜索")
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
            SortButton(selectedFilter: $selectedFilter, selectedSort: $selectedSort)
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
    HomeView_iOS()
}
#endif
