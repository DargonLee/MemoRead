//
//  ReadingCardModel.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

@Model
final class ReadingCardModel {
    // 基本信息
    var content: String
    var type: ReadingCardType.RawValue

    // 时间相关
    var createdAt: Date
    var notificationAt: Date?
    var completedAt: Date?
    var reminderAt: Date?

    // 状态
    var isCompleted: Bool

    init(content: String) {
        self.content = content
        self.type =
            content.isValidURL
            ? ReadingCardType.link.rawValue
            : (content.isValidImageData
                ? ReadingCardType.image.rawValue : ReadingCardType.text.rawValue)
        self.createdAt = Date()
        self.isCompleted = false
    }

    func setCompleted() {
        self.isCompleted = true
        self.completedAt = Date()
    }

    // 示例数据
    static func sampleData() -> [ReadingCardModel] {
        var samples = [
            // 长文本卡片
            ReadingCardModel(
                content: """
                    SwiftUI 是一个创新的、简单的构建用户界面的框架。它提供了声明式的语法，\
                    让开发者能够轻松创建漂亮的用户界面。通过SwiftUI，您可以使用更少的代码\
                    实现更多的功能。
                    """),

            // 链接卡片
            ReadingCardModel(content: "https://developer.apple.com/xcode/swiftui/"),

            // 短文本卡片
            ReadingCardModel(content: "本文整理了iOS开发中常用的一些技巧和注意事项..."),
        ]

        // 创建示例图片卡片
        let image: PlatformImage? = {
            #if os(iOS)
                return UIImage(named: "sampleImage")
            #elseif os(macOS)
                return NSImage(named: "sampleImage")
            #endif
        }()

        guard let platformImage = image,
            let imageModel = ReadingCardModel.createFromImage(platformImage)
        else {
            return samples
        }
        samples.append(imageModel)
        return samples
    }
}

extension ReadingCardModel {
    var image: Image? {
        guard type == ReadingCardType.image.rawValue else { return nil }
        return Image.create(from: content)
    }
    
    static func createFromImage(_ image: PlatformImage) -> ReadingCardModel? {
        guard let imageData = image.compressedData(compressionQuality: 0.8) else {
            return nil
        }
        let base64String = imageData.base64EncodedString()
        return ReadingCardModel(content: base64String)
    }
}
