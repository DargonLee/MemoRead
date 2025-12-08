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
            switch ReadingCardModel.ReadingCardType(rawValue: item.type) {
            case .image:
                ContentImageView(item: item)
            case .link:
                ContentLinkView(item: item)
            case .text:
                ContentTextView(content: item.content)
            case .none:
                ContentUnavailableView(
                    "Empty", image: "doc.text.magnifyingglass", description: Text("Empty"))
            }
        }
#if os(macOS)
        .contextMenu {
            Button("Delete") {}
            Button("Copy") {}
        }
#endif
    }
}

private struct ContentImageView: View {
    let item: ReadingCardModel
    
    private var titleAndContent: (title: String?, hasImage: Bool) {
        let lines = item.content.components(separatedBy: .newlines)
        if let firstLine = lines.first, !firstLine.isEmpty, !firstLine.isValidImageData {
            return (firstLine, true)
        }
        return (nil, true)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = titleAndContent.title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            if let image = item.image {
                image
                    .resizable()
                    .scaledToFill()
                    .cornerRadius(8)
                    .frame(maxHeight: 300)
                    .clipped()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 60)
                        .foregroundColor(.gray)
                    Text("Image not found")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 100)
            }
        }
    }
}

private struct ContentTextView: View {
    let content: String
    
    private var titleAndBody: (title: String?, body: String) {
        let lines = content.components(separatedBy: .newlines)
        if lines.count > 1, let firstLine = lines.first, !firstLine.isEmpty {
            let body = lines.dropFirst().joined(separator: "\n")
            return (firstLine, body.isEmpty ? content : body)
        }
        return (nil, content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = titleAndBody.title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(titleAndBody.body)
                .font(.body)
#if os(iOS)
                .lineLimit(3)
#elseif os(macOS)
                .lineLimit(5)
#endif
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }
}

private struct ContentLinkView: View {
    let item: ReadingCardModel
    
    private var url: URL? {
        URL(string: item.content)
    }
    
    private var titleAndDescription: (title: String?, description: String?) {
        // 如果内容包含换行，第一行可能是标题，第二行可能是描述
        let lines = item.content.components(separatedBy: .newlines)
        if lines.count >= 2 {
            let firstLine = lines[0].trimmingCharacters(in: .whitespaces)
            let secondLine = lines[1].trimmingCharacters(in: .whitespaces)
            // 检查第一行是否是URL
            if firstLine.isValidURL {
                return (nil, secondLine.isEmpty ? nil : secondLine)
            } else {
                return (firstLine.isEmpty ? nil : firstLine, secondLine.isEmpty ? nil : secondLine)
            }
        }
        return (nil, nil)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = titleAndDescription.title {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            if let description = titleAndDescription.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            if let url = url {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("EXTERNAL LINK")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(url.absoluteString)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Text(item.content)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
    }
}

#Preview {
    ReadingCardContentView(item: ReadingCardModel.sampleCards()[0])
}
