//
//  ReadingListView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI
import SwiftData

struct ReadingCardListView: View {
    @Environment(HomeViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    
    @Query private var readingCards: [ReadingCardModel]
    
    init(
        searchText: String = "",
        sortParameter: ReadingCardSortParameter = .all,
        sortOrder: ReadingCardSortOrder = .timeDescending
    ) {
        let predicate = ReadingCardModel.predicate(searchText: searchText, sortParameter: sortParameter)
        switch sortOrder {
        case .timeAscending:
            _readingCards = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .forward
            )
        case .timeDescending:
            _readingCards = Query(
                filter: predicate,
                sort: \.createdAt,
                order: .reverse
            )
        }
    }
    
    var body: some View {
        List {
            ForEach(readingCards) { item in
                ReadingCardView(item: item)
                    .listRowSeparator(.hidden)
            }
            .onDelete { indices in
                indices.forEach { index in
                    let card = readingCards[index]
                    context.delete(card)
                }
            }
        }
        .listStyle(.plain)
    }
}
