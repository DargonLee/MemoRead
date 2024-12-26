//
//  HomeView_iOS.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

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
                ReadingCardListView(readingCards: ReadingCardModel.sampleData())
                    .searchable(text: $searchText, prompt: "搜索")
                    .navigationTitle("MemoRead")
                    .toolbar {
                        toolbarItem()
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
            filterMenu
        }
    }

    private var settingsButton: some View {
        Button(action: {
            isSettingPresented = true
        }) {
            Image(systemName: "gearshape")
        }
    }

    private var filterMenu: some View {
        Menu {
            // 筛选选项
            Section {
                ForEach(ReadingCardSortType.allCases) { filter in
                    Button(action: { selectedFilter = filter }) {
                        Label(filter.title, systemImage: selectedFilter == filter ? "checkmark" : "")
                    }
                }
            }

            // 排序选项 
            Section {
                ForEach(ReadingCardSortOption.allCases) { sort in
                    Button(action: { selectedSort = sort }) {
                        Label(sort.title, systemImage: selectedSort == sort ? "checkmark" : "")
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

#Preview {
    HomeView_iOS()
}
