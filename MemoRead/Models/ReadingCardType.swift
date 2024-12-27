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
    case automatic
    case light
    case dark

    var id: Self {
        self
    }

    var description: String {
        switch self {
        case .automatic: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var icon: String {
        switch self {
        case .automatic: return "circle.lefthalf.filled"
        case .light: return "sun.min.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum SidebarItem: CaseIterable, Identifiable {
    case all
    case text
    case link
    case image

    var id: Self { self }

    var title: String {
        switch self {
        case .all: return "所有"
        case .text: return "文本"
        case .link: return "链接"
        case .image: return "图片"
        }
    }

    var icon: String {
        switch self {
        case .all: return "note.text"
        case .text: return "doc.text"
        case .link: return "link"
        case .image: return "photo"
        }
    }

    var type: ReadingCardSortParameter {
        switch self {
        case .all: return .all
        case .text: return .text
        case .link: return .link
        case .image: return .image
        }
    }
}
