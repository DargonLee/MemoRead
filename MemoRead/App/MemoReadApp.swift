//
//  MemoReadApp.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/24.
//

import SwiftUI

@main
struct MemoReadApp: App {
    @State private var viewModel = HomeViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(viewModel)
        }
        .modelContainer(for: ReadingCardModel.self)
    }
}
