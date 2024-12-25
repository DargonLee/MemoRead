//
//  Helpers.swift
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

#if os(iOS) || os(visionOS)
typealias PlatformClipboardImage = UIImage
#else
typealias PlatformClipboardImage = NSImage
#endif

protocol PlatformImage {
    func compressedData(compressionQuality: CGFloat) -> Data?
}

#if os(iOS)
extension UIImage: PlatformImage {
    func compressedData(compressionQuality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
}
#endif

#if os(macOS)
extension NSImage: PlatformImage {
    func compressedData(compressionQuality: CGFloat) -> Data? {
        guard let imageData = self.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: imageData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            return nil
        }
        return jpegData
    }
}
#endif
