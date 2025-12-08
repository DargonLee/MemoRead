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
    
    private var imageAndText: (imageData: String?, text: String?) {
        let lines = item.content.components(separatedBy: .newlines)
        var imageData: String? = nil
        var text: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.isValidImageData {
                imageData = trimmed
            } else {
                if text == nil {
                    text = trimmed
                } else {
                    text = (text ?? "") + "\n" + trimmed
                }
            }
        }
        
        // 如果没有找到文本，尝试从原始内容中提取
        if text == nil && imageData == nil {
            // 可能是base64编码的图片数据
            imageData = item.content
        }
        
        return (imageData ?? item.content, text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            
            // 图片下方的文本
            if let text = imageAndText.text, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .padding(.top, 4)
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
    
    private var isQuoteCard: Bool {
        // 检查是否是引用卡片（包含引号或特定格式）
        content.contains("\"") || content.contains("\"\"\"")
    }

    var body: some View {
        if isQuoteCard {
            // 引用卡片样式
            QuoteCardView(content: content)
        } else {
            // 普通文本卡片
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
}

// MARK: - Quote Card View
private struct QuoteCardView: View {
    let content: String
    
    private var quoteParts: (quote: String, author: String?) {
        let lines = content.components(separatedBy: .newlines)
        var quote = ""
        var author: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("\"") || trimmed.hasPrefix("\"\"\"") {
                quote = trimmed
            } else if trimmed.hasPrefix("-") {
                author = String(trimmed.dropFirst().trimmingCharacters(in: .whitespaces))
            } else if !quote.isEmpty && author == nil {
                author = trimmed
            } else if quote.isEmpty {
                quote = trimmed
            }
        }
        
        return (quote.isEmpty ? content : quote, author)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 引用文本卡片
            VStack(alignment: .leading, spacing: 8) {
                Text(quoteParts.quote)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .italic()
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                if let author = quoteParts.author {
                    HStack {
                        Spacer()
                        Text("- \(author)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
            
            // 下方文本（如果有）
            let remainingText = content.components(separatedBy: .newlines)
                .filter { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return !trimmed.hasPrefix("\"") && !trimmed.hasPrefix("\"\"\"") && !trimmed.hasPrefix("-")
                }
                .joined(separator: "\n")
            
            if !remainingText.isEmpty && remainingText != content {
                Text(remainingText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
    }
}

private struct ContentLinkView: View {
    let item: ReadingCardModel
    
    private var url: URL? {
        // 从内容中提取URL
        let lines = item.content.components(separatedBy: .newlines)
        for line in lines {
            if let url = URL(string: line.trimmingCharacters(in: .whitespaces)), line.isValidURL {
                return url
            }
        }
        return URL(string: item.content)
    }
    
    private var titleAndDescription: (title: String?, description: String?) {
        let lines = item.content.components(separatedBy: .newlines)
        var title: String? = nil
        var description: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if trimmed.isValidURL {
                // 跳过URL行
                continue
            } else if title == nil {
                title = trimmed
            } else if description == nil {
                description = trimmed
            }
        }
        
        return (title, description)
    }
    
    private var isSocialMediaCard: Bool {
        // 检查是否是社交媒体卡片（包含特定关键词或格式）
        let content = item.content.lowercased()
        let lines = item.content.components(separatedBy: .newlines)
        
        // 检查是否包含社交媒体特征
        let hasSocialMediaFeatures = content.contains("twitter") || 
                                     content.contains("x.com") ||
                                     (content.contains("@") && content.contains("http")) ||
                                     lines.contains(where: { $0.contains("@") && $0.contains("http") })
        
        return hasSocialMediaFeatures
    }
    
    var body: some View {
        if isSocialMediaCard {
            // 社交媒体卡片样式
            SocialMediaCardView(item: item, url: url)
        } else {
            // 普通链接卡片
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
}

// MARK: - Social Media Card View
private struct SocialMediaCardView: View {
    let item: ReadingCardModel
    let url: URL?
    
    private var cardContent: (username: String?, handle: String?, text: String?, timestamp: String?) {
        let lines = item.content.components(separatedBy: .newlines)
        var username: String? = nil
        var handle: String? = nil
        var text: String? = nil
        var timestamp: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.isValidURL { continue }
            
            // 尝试解析社交媒体格式
            if trimmed.contains("@") && handle == nil {
                let parts = trimmed.components(separatedBy: "@")
                if parts.count >= 2 {
                    username = parts[0].trimmingCharacters(in: .whitespaces)
                    handle = "@" + (
                        parts[1].components(separatedBy: .whitespaces).first ?? ""
                    )
                }
            } else if text == nil && !trimmed.hasPrefix("http") {
                text = trimmed
            } else if trimmed.contains("·") || trimmed.contains("/") {
                timestamp = trimmed
            }
        }
        
        return (username, handle, text, timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 社交媒体卡片
            VStack(alignment: .leading, spacing: 12) {
                // 头部
                HStack(alignment: .top, spacing: 8) {
                    // 头像占位
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(cardContent.username ?? "User")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if let handle = cardContent.handle {
                                Text(handle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Text("X.com")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // 内容
                if let text = cardContent.text {
                    Text(text)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
                
                // URL链接
                if let url = url {
                    Link(destination: url) {
                        Text(url.absoluteString)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                
                // 时间戳
                if let timestamp = cardContent.timestamp {
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            
            // 下方文本（如果有）
            let remainingLines = item.content.components(separatedBy: .newlines)
                .filter { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return !trimmed.isValidURL && !trimmed.contains("@") && 
                           !trimmed.contains("·") && !trimmed.contains("/") &&
                           trimmed != cardContent.text
                }
            
            if !remainingLines.isEmpty {
                Text(remainingLines.joined(separator: "\n"))
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
    }
}

#Preview {
    ReadingCardContentView(item: ReadingCardModel.sampleCards()[0])
}
