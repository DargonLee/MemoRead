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
        #if os(iOS)
        UIPasteboard.general.string = self
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(self, forType: .string)
        #endif

        #if DEBUG
        Logger.main.debug("Copied to clipboard: \(self)")
        #endif
    }
    
    // Check if a string is a valid URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // Check if a string is a valid image base64 encoded data
    var isValidImageData: Bool {
        return Data(base64Encoded: self) != nil
    }
}


