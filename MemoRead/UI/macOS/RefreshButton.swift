//
//  RefreshButton.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/27.
//

import SwiftUI

struct RefreshButton: View {
    @Environment(\.refresh) private var refresh
    
    var body: some View {
        Button {
            Task {
                await refresh?()
            }
        }label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }
}

#Preview {
    RefreshButton()
}
