//
//  HomeView_macOS.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

#if os(macOS)
struct HomeView_macOS: View {
    @Environment(HomeViewModel.self) private var viewModel
    
    // MARK: - Body
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationSplitView {
            SidebarView(sortParameter: $viewModel.sortParameter)
        } detail: {
            MemoListView(
                searchText: $viewModel.searchText,
                sortParameter: $viewModel.sortParameter,
                sortOrder: $viewModel.sortOrder
            )
        }
    }
}

// MARK: - Sidebar View
private struct SidebarView: View {
    @Binding var sortParameter: ReadingCardSortParameter
    @State private var showSettings = false
    
    var body: some View {
        List(selection: $sortParameter) {
            ForEach(SidebarItem.allCases) { item in
                NavigationLink(value: item.type) {
                    Label(item.title, systemImage: item.icon)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button(action: { showSettings.toggle() }) {
                Label("Setting", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .buttonStyle(.borderless)
        }
        .sheet(isPresented: $showSettings) {
            SettingView()
        }
    }
}

// MARK: - Memo List View
private struct MemoListView: View {
    @Binding var searchText: String
    @Binding var sortParameter: ReadingCardSortParameter
    @Binding var sortOrder: ReadingCardSortOrder
    
    @State private var showAddSheet: Bool = true
    
    var body: some View {
        ZStack {
            VStack {
                ReadingCardListView(
                    searchText: searchText,
                    sortParameter: sortParameter,
                    sortOrder: sortOrder
                )
                .searchable(text: $searchText, prompt: "Search")
            }
            .navigationTitle("MemoRead")
            .toolbar {
#if os(macOS)
                RefreshButton()
#endif
                sortButton
            }
            .sheet(isPresented: $showAddSheet) {
                AddCardView()
            }
            AddButton(addAction: {
                showAddSheet = true
            })
        }
    }
    
    private var sortButton: some View {
        Menu {
            ForEach(ReadingCardSortOrder.allCases) { option in
                Button(action: { sortOrder = option }) {
                    HStack {
                        Text(option.name)
                        Spacer()
                        if sortOrder == option {
                            Image(systemName: "checkmark.circle")
                        } else {
                            Image(systemName: "circle")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

#Preview {
    @Previewable @State var viewModel = HomeViewModel()
    let preview = Preview(ReadingCardModel.self)
    let cards = ReadingCardModel.sampleCards()
    preview.addExamples(cards)
    return HomeView_macOS()
        .environment(viewModel)
        .modelContainer(preview.container)
}
#endif
