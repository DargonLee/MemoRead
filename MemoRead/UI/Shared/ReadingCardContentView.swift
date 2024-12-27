//
//  ReadingCardContentView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

struct ReadingCardContentView: View {
    let item: ReadingCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.type {
            case .image:
                ContentImageView(item: item)
            case .link:
                ContentLinkView(content: item.content)
            case .text:
                ContentTextView(content: item.content)
            }
        }
#if os(macOS)
        .contextMenu {
            Button("删除") { }
            Button("复制") { }
        }
#endif
    }
}

private struct ContentImageView: View {
    let item: ReadingCardModel

    var body: some View {
        if let image = item.image {
            image
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
                .frame(maxHeight: 200)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.exclamationmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .foregroundColor(.gray)
                Text("图片解析失败")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(height: 100)
        }
    }
}

private struct ContentTextView: View {
    let content: String
    
    var body: some View {
        Text(content)
            .font(.body)
#if os(iOS)
            .lineLimit(3)
#elseif os(macOS)
            .lineLimit(5)
#endif
            .multilineTextAlignment(.leading)
            .lineSpacing(6)
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
    }
}

private struct ContentLinkView: View {
    let content: String

    var body: some View {
        let url = URL(string: content)!
        return Link(destination: url) {
            Text(url.absoluteString)
#if os(iOS)
            .lineLimit(3)
#elseif os(macOS)
            .lineLimit(5)
#endif
        }
    }
}

#Preview {
    ReadingCardContentView(item: ReadingCardModel.sampleCards()[0])
}
