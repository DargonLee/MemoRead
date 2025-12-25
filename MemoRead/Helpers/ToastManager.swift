//
//  ToastManager.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toast: Toast?
    
    private var workItem: DispatchWorkItem?
    
    private init() {}
    
    func show(_ message: String, style: Toast.Style = .info, duration: TimeInterval = 2.0) {
        // 取消之前的定时器
        workItem?.cancel()
        
        // 显示新的 Toast
        toast = Toast(message: message, style: style, duration: duration)
        
        // 设置自动隐藏
        let task = DispatchWorkItem { [weak self] in
            self?.toast = nil
        }
        workItem = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
    
    func dismiss() {
        workItem?.cancel()
        toast = nil
    }
}

