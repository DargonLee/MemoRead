//
//  HomeViewModel.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/27.
//

import Foundation

@Observable
class HomeViewModel {
    var sortParameter: ReadingCardSortParameter = .all
    var sortOrder: ReadingCardSortOrder = .timeDescending
    var searchText: String = ""
    
}
