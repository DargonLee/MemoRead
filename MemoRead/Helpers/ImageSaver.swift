//
//  ImageSaver.swift
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

/// 图片保存工具类
final class ImageSaver {
    static let shared = ImageSaver()
    
    private init() {}
    
    /// 保存图片
    /// - Parameter image: 要保存的图片
    func saveImage(_ image: PlatformImage) {
        #if os(iOS)
        saveToPhotosAlbum(image)
        #elseif os(macOS)
        saveWithPanel(image)
        #endif
    }
    
    #if os(iOS)
    private func saveToPhotosAlbum(_ image: PlatformImage) {
        UIImageWriteToSavedPhotosAlbum(image as! UIImage, nil, nil, nil)
    }
    #elseif os(macOS)
    private func saveWithPanel(_ image: PlatformImage) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "image.jpg"
        
        panel.begin { result in
            if result == .OK,
               let url = panel.url,
               let imageData = image.compressedData(compressionQuality: 1.0) {
                try? imageData.write(to: url)
            }
        }
    }
    #endif
}
