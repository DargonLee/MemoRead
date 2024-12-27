//
//  ReadingCardType.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import Foundation

enum ReadingCardSortParameter: String, Identifiable, CaseIterable {
    case all = "all"
    case text = "doc"
    case link = "link"
    case image = "image"

    var name: String {
        switch self {
        case .all: return "全部"
        case .text: return "文本"
        case .link: return "链接"
        case .image: return "图片"
        }
    }

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .text: return "doc.text"
        case .link: return "link"
        case .image: return "photo"
        }
    }

    var id: Self {
        self
    }

    var toCardType: ReadingCardModel.ReadingCardType {
        if self == .link {
            return .link
        } else if self == .image {
            return .image
        }
        return .text
    }
}

enum ReadingCardSortOrder: String, Identifiable, CaseIterable {
    case timeDescending
    case timeAscending

    var name: String {
        switch self {
        case .timeDescending: return "最新"
        case .timeAscending: return "最早"
        }
    }

    var icon: String {
        switch self {
        case .timeAscending: return "arrow.up.calendar"
        case .timeDescending: return "arrow.down.calendar"
        }
    }

    var id: Self {
        self
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case automatic, light, dark

    var id: Self { self }

    private static let properties: [Self: (description: String, icon: String)] = [
        .automatic: ("自动", "circle.lefthalf.filled"),
        .light: ("浅色", "sun.min.fill"),
        .dark: ("深色", "moon.fill")
    ]

    var description: String {
        Self.properties[self]?.description ?? ""
    }

    var icon: String {
        Self.properties[self]?.icon ?? ""
    }
}

enum SidebarItem: CaseIterable, Identifiable {
    case all, text, link, image

    var id: Self { self }

    private static let properties: [Self: (title: String, icon: String, type: ReadingCardSortParameter)] = [
        .all: ("所有", "note.text", .all),
        .text: ("文本", "doc.text", .text),
        .link: ("链接", "link", .link),
        .image: ("图片", "photo", .image)
    ]

    var title: String {
        Self.properties[self]?.title ?? ""
    }

    var icon: String {
        Self.properties[self]?.icon ?? ""
    }

    var type: ReadingCardSortParameter {
        Self.properties[self]?.type ?? .all
    }
}
