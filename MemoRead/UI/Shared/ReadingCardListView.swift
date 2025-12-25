//
//  ReadingListView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI
import SwiftData

struct ReadingCardListView: View {
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
        Group {
            if readingCards.isEmpty {
                ContentUnavailableView(
                    "No Cards",
                    systemImage: "book.closed",
                    description: Text("No reading cards found. Add cards on iOS device to sync.")
                )
            } else {
                List {
                    ForEach(Array(readingCards.enumerated()), id: \.element.id) { index, item in
                        TimelineCardView(
                            item: item,
                            isLast: index == readingCards.count - 1
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.bottom, index == readingCards.count - 1 ? 16 : 0)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }
}
