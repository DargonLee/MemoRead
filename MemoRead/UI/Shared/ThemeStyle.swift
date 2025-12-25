//
//  ThemeStyle.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/16.
//

import SwiftUI

enum ThemeStyle {
    // MARK: - Colors
    /// 全局强调色，使用系统默认蓝色以保持平台一致性
    static let accent = Color(.systemBlue)
    /// 卡片/弹窗背景基色
    static let background = Color.white.opacity(0.9)
    
    // MARK: - Timeline Style
    /// 时间线强调色
    static let timelineAccent = Color.blue
    /// 时间线连接线颜色
    static let timelineLine = Color.blue.opacity(0.3)
    /// 卡片阴影颜色
    static let cardShadow = Color.black
    
    /// 卡片背景色（平台适配）
    static var cardBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return .white
        #endif
    }
    
    /// 列表背景色（平台适配）
    static var listBackground: Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color.clear
        #endif
    }
}

