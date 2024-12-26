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

#if os(iOS)
    typealias PlatformImageType = UIImage
#else
    typealias PlatformImageType = NSImage
#endif

protocol PlatformImage {
    func compressedData(compressionQuality: CGFloat) -> Data?
}

protocol PlatformImageView {
    static func create(from data: Data) -> Image?
    static func create(from base64String: String) -> Image?
}

#if os(iOS)
extension UIImage: PlatformImage {
    func compressedData(compressionQuality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
}
extension Image: PlatformImageView {
    static func create(from data: Data) -> Image? {
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    static func create(from base64String: String) -> Image? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return create(from: data)
    }
}
#endif

#if os(macOS)
extension NSImage: PlatformImage {
    func compressedData(compressionQuality: CGFloat) -> Data? {
        guard let imageData = self.tiffRepresentation,
            let bitmapRep = NSBitmapImageRep(data: imageData),
            let jpegData = bitmapRep.representation(
                using: .jpeg, properties: [.compressionFactor: compressionQuality])
        else {
            return nil
        }
        return jpegData
    }
}
extension Image: PlatformImageView {
    static func create(from data: Data) -> Image? {
        guard let nsImage = NSImage(data: data),
            let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }
        return Image(decorative: cgImage, scale: 1.0)
    }

    static func create(from base64String: String) -> Image? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return create(from: data)
    }
}
#endif
