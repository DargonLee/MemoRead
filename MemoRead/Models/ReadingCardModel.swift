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
    var type: ReadingCardType

    // 时间相关
    var createdAt: Date
    var reminderAt: Date?
    var completedAt: Date?

    // 状态
    var isCompleted: Bool

    init(
        content: String,
        createdAt: Date = Date(),
        reminderAt: Date = Date.distantPast
    ) {
        self.content = content
        self.type =
        content.isValidURL
        ? ReadingCardType.link
        : (
            content.isValidImageData
            ? ReadingCardType.image : ReadingCardType.text
        )
        self.createdAt = createdAt
        self.reminderAt = reminderAt
        self.isCompleted = false
    }

    func setCompleted() {
        self.isCompleted = true
        self.completedAt = Date()
    }
}

extension ReadingCardModel {
    enum ReadingCardType: String, CaseIterable, Codable {
        case text = "doc"
        case link = "link"
        case image = "image"

        var icon: String {
            switch self {
            case .text:
                return "doc.text"
            case .link:
                return "link"
            case .image:
                return "photo"
            }
        }
    }
}

extension ReadingCardModel {
    var image: Image? {
        guard type == ReadingCardType.image else { return nil }
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

extension ReadingCardModel {
    static func predicate(searchText: String, sortParameter: ReadingCardSortParameter) -> Predicate<ReadingCardModel> {
        return #Predicate<ReadingCardModel> { model in
            (searchText.isEmpty || model.content.contains(searchText))
//            let textCondition = searchText.isEmpty || model.content.contains(searchText)
//            let typeCondition = switch sortParameter {
//                case .all: true
//                case .text: model.type == .text
//                case .link: model.type == .link
//                case .image: model.type == .image
//            }
//            textCondition && typeCondition
        }
    }
}

extension ReadingCardModel {
    // 示例数据
    static func sampleCards() -> [ReadingCardModel] {
        var samples = [
            // 长文本卡片
            ReadingCardModel(
                content: """
                    SwiftUI 是一个创新的、简单的构建用户界面的框架。它提供了声明式的语法，\
                    让开发者能够轻松创建漂亮的用户界面。通过SwiftUI，您可以使用更少的代码\
                    实现更多的功能。
                    """,
                createdAt: .now.addingTimeInterval(-86400 * 3)), // 3天前
            
            // 链接卡片
            ReadingCardModel(
                content: "https://developer.apple.com/xcode/swiftui/",
                createdAt: .now.addingTimeInterval(-86400)), // 1天前
            
            // 短文本卡片
            ReadingCardModel(
                content: "本文整理了iOS开发中常用的一些技巧和注意事项...",
                createdAt: .now.addingTimeInterval(-86400 * 2)), // 2天前
                
            // 技术文章卡片
            ReadingCardModel(
                content: """
                    Swift并发编程中的async/await是一个强大的特性,它可以让异步代码的编写变得更加简单和直观。\
                    通过使用async关键字标记异步函数,await关键字等待异步操作完成,我们可以用同步的方式编写异步代码。
                    """,
                createdAt: .now), // 现在
                
            // 开发文档链接
            ReadingCardModel(
                content: "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/",
                createdAt: .now.addingTimeInterval(-3600)), // 1小时前
                
            // 学习笔记
            ReadingCardModel(
                content: "SwiftUI中的@State、@Binding、@StateObject等属性包装器的使用场景和区别...",
                createdAt: .now.addingTimeInterval(-7200)), // 2小时前
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
