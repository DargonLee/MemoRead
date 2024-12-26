//
//  Modifiers.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

// MARK: - Chip Style Modifier
struct ChipModifier: ViewModifier {
    let color: Color
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// MARK: - View Extension
extension View {
    func chipStyle(color: Color = .blue) -> some View {
        modifier(ChipModifier(color: color))
    }
}
