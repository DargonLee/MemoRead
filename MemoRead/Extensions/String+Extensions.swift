//
//  String+Extensions.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import OSLog

extension String {
    func copyToClipboard() {
        Clipboard.shared.setString(self)
        #if DEBUG
        Logger.main.debug("Copied to clipboard: \(self)")
        #endif
    }
    
    // Check if a string is a valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else {
            return false
        }
#if os(iOS)
        return UIApplication.shared.canOpenURL(url)
#elseif os(macOS)
        return NSWorkspace.shared.open(url)
#endif
    }
    
    // Check if a string is a valid image base64 encoded data
    var isValidImageData: Bool {
        return Data(base64Encoded: self) != nil
    }
}


