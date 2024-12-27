//
//  SortButton.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/27.
//

import SwiftUI

struct SortButton: View {
    @Binding var selectedFilter: ReadingCardSortType
    @Binding var selectedSort: ReadingCardSortOption
    
    var body: some View {
        Menu {
            Picker("Sort By", selection: $selectedFilter) {
                ForEach(ReadingCardSortType.allCases) { order in
                    Text(order.name)
                }
            }

            Picker("Sort Order", selection: $selectedSort) {
                ForEach(ReadingCardSortOption.allCases) { order in
                    Text(order.name)
                }
            }
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}
