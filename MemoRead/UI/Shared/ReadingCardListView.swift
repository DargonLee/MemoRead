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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(readingCards.enumerated()), id: \.element.id) { index, item in
                    TimelineCardView(
                        item: item,
                        isLast: index == readingCards.count - 1
                    )
                    .padding(.bottom, index == readingCards.count - 1 ? 16 : 0)
                }
            }
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(white: 0.96),
                    Color(white: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
