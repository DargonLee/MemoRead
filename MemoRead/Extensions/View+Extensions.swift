//
//  View+Extensions.swift
//  MemoRead
//
//  Created by Harlan on 2025/12/25.
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

struct TextEditorPaddingModifier: ViewModifier {
    let padding: EdgeInsets
    
    init(padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(padding)
#if os(macOS)
            .background(Color(.textBackgroundColor))
#else
            .background(Color(.systemBackground))
#endif
            .cornerRadius(8)
    }
}

extension View {
    func textEditorPadding(_ padding: EdgeInsets = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)) -> some View {
        modifier(TextEditorPaddingModifier(padding: padding))
    }
}
