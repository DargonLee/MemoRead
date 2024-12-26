//
//  String+Extensions.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import Foundation
import UniformTypeIdentifiers
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
        guard let url = URL(string: self),
              !url.absoluteString.isEmpty else {
            return false
        }
        guard let scheme = url.scheme?.lowercased(),
              ["http", "https", "ftp"].contains(scheme) else {
            return false
        }
        
#if os(iOS)
        return UIApplication.shared.canOpenURL(url)
#elseif os(macOS)
        guard let host = url.host,
              !host.isEmpty else {
            return false
        }
        if url.isFileURL,
           let uttype = UTType(filenameExtension: url.pathExtension) {
            return uttype.conforms(to: .html) ||
            uttype.conforms(to: .webArchive) ||
            uttype.conforms(to: .text)
        }
        return true
#endif
    }
    
    // Check if a string is a valid image base64 encoded data
    var isValidImageData: Bool {
        return Data(base64Encoded: self) != nil
    }
}


