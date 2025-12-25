//
//  AddButton.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

struct AddButton: View {
    let addAction: () -> Void
    
    @ObservedObject private var syncService = MultipeerSyncService.shared
    @State private var breathingScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0.0
    
    // 根据连接状态确定按钮颜色
    private var buttonColor: Color {
        if syncService.isConnected {
            // 已连接：绿色
            return .green
        } else {
            // 未连接：橙色
            return .orange
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    addAction()
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotationAngle))
                        .frame(width: 45, height: 45)
                        .background(buttonColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .scaleEffect(breathingScale)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            if !syncService.isConnected {
                startBreathingAnimation()
            }
        }
        .onChange(of: syncService.isConnected) { oldValue, newValue in
            if newValue {
                // 连接成功，停止动画
                stopAnimations()
            } else {
                // 断开连接，重启动画
                startBreathingAnimation()
            }
        }
    }
    
    // MARK: - Animations
    private func startBreathingAnimation() {
        // 呼吸动画
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.15
        }
        
        // 旋转动画
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    private func stopAnimations() {
        // 停止所有动画，重置为初始状态
        withAnimation(.easeOut(duration: 0.3)) {
            breathingScale = 1.0
            rotationAngle = 0.0
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    AddButton {
        
    }
}
