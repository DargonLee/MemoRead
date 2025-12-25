//
//  ToastView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

// MARK: - Toast Model
struct Toast: Equatable {
    enum Style {
        case success
        case error
        case info
        case warning
    }
    
    let message: String
    let style: Style
    let duration: TimeInterval
    
    init(message: String, style: Style = .info, duration: TimeInterval = 2.0) {
        self.message = message
        self.style = style
        self.duration = duration
    }
    
    var icon: String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch style {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    
    // 宽度配置
    private let minWidth: CGFloat = 100
    #if os(macOS)
    private let maxWidth: CGFloat = NSScreen.main?.frame.width ?? 350
    #endif
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon)
                .font(.system(size: 20))
                .foregroundColor(toast.color)
                .fixedSize()
            
            Text(toast.message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minWidth: minWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(toast.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 短文本
        ToastView(toast: Toast(message: "成功", style: .success))
        
        // 中等长度文本
        ToastView(toast: Toast(message: "已连接 iPhone，开始同步", style: .info))
        
        // 长文本
        ToastView(toast: Toast(message: "同步失败：网络连接超时，请检查网络设置后重试", style: .error))
        
        // 超长文本（会换行）
        ToastView(toast: Toast(message: "警告：检测到多个设备同时连接，可能会导致数据冲突，建议断开其他设备后重新连接", style: .warning))
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

