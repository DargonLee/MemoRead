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
    @AppStorage("app_appearance") private var selectedAppearance: Appearance = .automatic
    
    init() {
        print(URL.applicationSupportDirectory.path(percentEncoded: false))
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(selectedAppearance.colorScheme)
                .environment(viewModel)
        }
        .modelContainer(for: ReadingCardModel.self)
    }
}
