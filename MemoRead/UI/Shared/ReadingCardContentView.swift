//
//  ReadingCardContentView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

// MARK: - Main
struct ReadingCardContentView: View {
    let item: ReadingCardModel
    
    private var parsedContent: ParsedContent {
        ParsedContent(from: item.content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ContentLayout.sectionSpacing) {
            // 图片（如果有）
            if let imageData = parsedContent.imageData {
                ImageDisplayView(imageData: imageData)
            }
            
            // 文本内容（如果有）
            if let text = parsedContent.text, !text.isEmpty {
                TextDisplayView(content: text)
            }
            
            // 链接（如果有）
            if let url = parsedContent.url {
                LinkDisplayView(url: url, item: item)
            }
            
            // 如果所有内容都为空，显示空状态
            if parsedContent.isEmpty {
                ContentUnavailableView(
                    "Empty", 
                    image: "doc.text.magnifyingglass", 
                    description: Text("Empty")
                )
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

// MARK: - Content Parser
private struct ParsedContent {
    let imageData: String?
    let text: String?
    let url: URL?
    
    var isEmpty: Bool {
        imageData == nil && text == nil && url == nil
    }
    
    init(from content: String) {
        let lines = content.components(separatedBy: .newlines)
        var imageData: String? = nil
        var textLines: [String] = []
        var url: URL? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // 检查是否是图片数据
            if trimmed.isValidImageData {
                imageData = trimmed
            }
            // 检查是否是URL
            else if trimmed.isValidURL, let parsedURL = URL(string: trimmed) {
                url = parsedURL
            }
            // 否则作为文本
            else {
                textLines.append(trimmed)
            }
        }
        
        // 如果没有找到图片数据，但整个内容是base64，可能是图片
        if imageData == nil && content.isValidImageData {
            imageData = content
        }
        
        // 如果没有找到URL，但整个内容是URL
        if url == nil && content.isValidURL, let parsedURL = URL(string: content) {
            url = parsedURL
        }
        
        self.imageData = imageData
        self.text = textLines.isEmpty ? nil : textLines.joined(separator: "\n")
        self.url = url
    }
}

// MARK: - Helpers
private enum ContentLineLimit {
    static var `default`: Int? {
#if os(iOS)
        return 3
#elseif os(macOS)
        return 5
#else
        return nil
#endif
    }
}

// MARK: - Image Display View
private struct ImageDisplayView: View {
    let imageData: String
    
    private var image: Image? {
        Image.create(from: imageData)
    }
    
    var body: some View {
        if let image = image {
            image
                .resizable()
                .scaledToFill()
                .cornerRadius(ContentLayout.cardCornerRadius)
                .frame(maxHeight: ContentLayout.imageMaxHeight)
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

// MARK: - Text Display View
private struct TextDisplayView: View {
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
                    .lineLimit(ContentLineLimit.default)
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
            .padding(ContentLayout.quotePadding)
            .background(ContentStyle.quoteBackground)
            .cornerRadius(ContentLayout.cardCornerRadius)
            
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

// MARK: - Link Display View
private struct LinkDisplayView: View {
    let url: URL
    let item: ReadingCardModel
    
    private var isSocialMediaCard: Bool {
        // 检查是否是社交媒体卡片（包含特定关键词或格式）
        let urlString = url.absoluteString.lowercased()
        let content = item.content.lowercased()
        
        // 检查是否包含社交媒体特征
        return urlString.contains("twitter") || 
               urlString.contains("x.com") ||
               content.contains("twitter") ||
               content.contains("x.com") ||
               (content.contains("@") && content.contains("http"))
    }
    
    var body: some View {
        if isSocialMediaCard {
            // 社交媒体卡片样式
            SocialMediaCardView(item: item, url: url)
        } else {
            // 普通链接卡片
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
                .background(ContentStyle.externalLinkBackground)
                .cornerRadius(ContentLayout.cardCornerRadius)
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
                        .frame(width: ContentLayout.socialAvatarSize, height: ContentLayout.socialAvatarSize)
                    
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
            .padding(ContentLayout.quotePadding)
            .background(ContentStyle.socialBackground)
            .cornerRadius(ContentLayout.cardCornerRadius)
            
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

// MARK: - Layout & Style
private enum ContentLayout {
    static let sectionSpacing: CGFloat = 12
    static let imageMaxHeight: CGFloat = 300
    static let quotePadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let socialAvatarSize: CGFloat = 40
}

private enum ContentStyle {
    static let quoteBackground = Color.gray.opacity(0.08)
    static let socialBackground = Color.black.opacity(0.8)
    static let externalLinkBackground = Color.gray.opacity(0.1)
}

#Preview {
    ReadingCardContentView(item: ReadingCardModel.sampleCards()[0])
}
