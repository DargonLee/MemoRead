//
//  ContentView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/24.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: Appearance = .automatic
    var body: some View {
        VStack {
#if os(iOS)
            HomeView_iOS()
#elseif os(macOS)
            HomeView_macOS()
#endif
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
    }
}

#Preview {
    HomeView()
}
