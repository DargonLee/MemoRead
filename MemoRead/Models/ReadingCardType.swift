//
//  ReadingCardType.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import Foundation

enum ReadingCardType: String, CaseIterable {
    // 文章类型
    case text = "文本"
    case link = "链接"
    case image = "图片"
    
    // 获取类型图标
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
