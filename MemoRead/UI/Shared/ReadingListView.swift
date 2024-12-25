//
//  ReadingListView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

struct ReadingListView: View {
    var readingCards: [ReadingCardModel]
    
    var body: some View {
        List {
            ForEach(readingCards) { item in
                ReadingCardView(item: item)
            }
        }
    }
}

#Preview {
    ReadingListView(readingCards: ReadingCardModel.sampleData())
}
