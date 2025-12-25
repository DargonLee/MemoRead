//
//  Color+Extensions.swift
//  MemoRead
//
//  Created by Harlan on 2025/12/25.
//

import SwiftUI

private struct RandomColorModifier: ViewModifier {
    let palette: [Color]
    
    func body(content: Content) -> some View {
        content
            .background(Color.random(from: palette))
    }
}

extension View {
    /// 给任意 View 添加随机背景色，可传入自定义色板
    func randomBackground(_ palette: [Color] = Color.defaultRandomPalette) -> some View {
        modifier(RandomColorModifier(palette: palette))
    }
}

extension Color {
    static var defaultRandomPalette: [Color] {
        [
            .blue, .indigo, .purple, .pink, .orange,
            .teal, .mint, .green, .cyan, .yellow
        ]
    }
    
    static func random(from palette: [Color] = Color.defaultRandomPalette) -> Color {
        if let chosen = palette.randomElement() {
            return chosen
        }
        return Color(
            hue: .random(in: 0...1),
            saturation: .random(in: 0.35...0.75),
            brightness: .random(in: 0.65...0.95)
        )
    }
}

