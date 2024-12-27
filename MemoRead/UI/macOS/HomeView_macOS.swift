//
//  HomeView_macOS.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI
struct HomeView_macOS: View {
    var body: some View {
        Text("macOS")
    }
}
//#if os(macOS)
//struct HomeView_macOS: View {
//    // MARK: - State
//    @State private var selectedType = ReadingCardModel.ReadingCardType.text
//    @State private var searchText: String = ""
//    @State private var sortOption: ReadingCardSortOrder = .timeAscending
//    
//    // MARK: - Body
//    var body: some View {
//        NavigationSplitView {
//            SidebarView(selectedType: $selectedType)
//        } detail: {
//            MemoListView(
//                selectedType: selectedType,
//                searchText: $searchText,
//                sortOption: $sortOption
//            )
//        }
//    }
//}
//
//// MARK: - Sidebar View
//private struct SidebarView: View {
//    @Binding var selectedType: ReadingCardModel.ReadingCardType
//    @State private var showSettings = false
//    
//    var body: some View {
//        List(selection: $selectedType) {
//            ForEach(SidebarItem.allCases) { item in
//                NavigationLink(value: item.type) {
//                    Label(item.title, systemImage: item.icon)
//                }
//            }
//        }
//        .listStyle(.sidebar)
//        .safeAreaInset(edge: .bottom) {
//            Button(action: { showSettings.toggle() }) {
//                Label("设置", systemImage: "gearshape")
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(8)
//            }
//            .buttonStyle(.borderless)
//        }
//        .sheet(isPresented: $showSettings) {
//            SettingView()
//        }
//    }
//}
//
//// MARK: - Memo List View
//private struct MemoListView: View {
//    let selectedType: ReadingCardModel.ReadingCardType?
//    @Binding var searchText: String
//    @Binding var sortOption: ReadingCardSortOrder
//    @State private var showAddSheet: Bool = true
//    
//    var body: some View {
//        ZStack {
//            VStack {
//                ReadingCardListView(
//                    readingCards: getFilteredCards()
//                )
//                .searchable(text: $searchText, prompt: "搜索")
//            }
//            .navigationTitle("MemoRead")
//            .toolbar {
//#if os(macOS)
//                RefreshButton()
//#endif
//                sortButton
//            }
//            .sheet(isPresented: $showAddSheet) {
//                AddCardView()
//            }
//            AddButton(addAction: {
//                showAddSheet = true
//            })
//        }
//    }
//    
//    private var sortButton: some View {
//        Menu {
//            ForEach(ReadingCardSortOption.allCases) { option in
//                Button(action: { sortOption = option }) {
//                    HStack {
//                        Text(option.title)
//                        Spacer()
//                        if sortOption == option {
//                            Image(systemName: "checkmark.circle")
//                        } else {
//                            Image(systemName: "circle")
//                        }
//                    }
//                }
//            }
//        } label: {
//            Image(systemName: "arrow.up.arrow.down")
//        }
//    }
//    
//    // MARK: - Helper Methods
//    private func getFilteredCards() -> [ReadingCardModel] {
//        var cards = ReadingCardModel.sampleData()
//        
//        // 应用类型过滤
//        if let type = selectedType {
//            cards = cards.filter { $0.type == type.rawValue }
//        }
//        
//        // 应用搜索过滤
//        if !searchText.isEmpty {
//            cards = cards.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
//        }
//        
//        // 应用排序
//        cards.sort { card1, card2 in
//            switch sortOption {
//            case .timeAscending:
//                return card1.createdAt < card2.createdAt
//            case .timeDescending:
//                return card1.createdAt > card2.createdAt
//            }
//        }
//        
//        return cards
//    }
//}
//
//#Preview {
//    HomeView_macOS()
//}
//#endif
