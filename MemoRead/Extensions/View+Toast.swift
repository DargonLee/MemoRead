//
//  View+Toast.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension View {
    func toast() -> some View {
        self.modifier(ToastModifier())
    }
}

struct ToastModifier: ViewModifier {
    @StateObject private var toastManager = ToastManager.shared
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    // Toast 位置配置（屏幕高度的 0.4 倍）
    private var topOffset: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height * 0.4
        #elseif os(macOS)
        return NSScreen.main?.frame.height ?? 600 * 0.4
        #else
        return 240
        #endif
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Toast overlay at screen level
            VStack {
                Spacer()
                    .frame(height: topOffset)
                
                if let toast = toastManager.toast {
                    ToastView(toast: toast)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.height < -10 {
                                        dismissToast()
                                    }
                                }
                        )
                }
                
                Spacer()
            }
            .ignoresSafeArea()
            .allowsHitTesting(toastManager.toast != nil)
            .zIndex(999)
        }
        .onChange(of: toastManager.toast) { oldValue, newValue in
            if newValue != nil {
                // 出现动画：从小变大，带弹簧效果
                showToast()
            } else {
                // 消失动画：从大变小，渐隐
                hideToast()
            }
        }
    }
    
    // MARK: - Animations
    private func showToast() {
        scale = 0.5
        opacity = 0
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func hideToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }
    }
    
    private func dismissToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            toastManager.dismiss()
        }
    }
}

