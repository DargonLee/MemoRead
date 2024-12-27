//
//  SortButton.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/27.
//

import SwiftUI

struct SortButton: View {
    @Environment(HomeViewModel.self) private var viewModel
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        Menu {
            Picker("Sort By", selection: $viewModel.sortParameter) {
                ForEach(ReadingCardSortParameter.allCases) { order in
                    Text(order.name)
                }
            }

            Picker("Sort Order", selection: $viewModel.sortOrder) {
                ForEach(ReadingCardSortOrder.allCases) { order in
                    Text(order.name)
                }
            }
        } label: {
            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}
