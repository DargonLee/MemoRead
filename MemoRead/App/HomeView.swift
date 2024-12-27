//
//  ContentView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
#if os(iOS)
            HomeView_iOS()
#elseif os(macOS)
            HomeView_macOS()
#endif
        }
        .refreshable {
            
        }
    }
}

#Preview {
    HomeView()
}
