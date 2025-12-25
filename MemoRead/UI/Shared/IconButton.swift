//
//  IconButton.swift
//  MemoRead
//
//  Created by Harlan on 2025/12/25.
//

import SwiftUI

// MARK: - Reusable Icon Button
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundColor(.secondary.opacity(0.6))
        }
    }
}
