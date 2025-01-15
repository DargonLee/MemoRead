//
//  Alert.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import SwiftUI

#if os(macOS)

extension NSAlert {
    static func showSuccess(message: String) {
        let alert = NSAlert()
        alert.messageText = "成功"
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    static func showError(message: String) {
        let alert = NSAlert()
        alert.messageText = "错误"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
#endif
