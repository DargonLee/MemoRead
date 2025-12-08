//
//  TimelineCardView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI

struct TimelineCardView: View {
    @Environment(\.modelContext) private var modelContext
    let item: ReadingCardModel
    let isLast: Bool
    @State private var isCompleted: Bool
    private var type: ReadingCardModel.ReadingCardType
    
    // MARK: - Initialization
    init(item: ReadingCardModel, isLast: Bool = false) {
        self.item = item
        self.isLast = isLast
        _isCompleted = State(initialValue: item.isCompleted)
        self.type = ReadingCardModel.ReadingCardType(rawValue: item.type)!
    }
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧时间线
            timelineIndicator
            
            // 右侧内容区域
            VStack(alignment: .leading, spacing: 12) {
                // 头部：时间戳和标签
                headerView
                
                // 内容区域
                ReadingCardContentView(item: item)
                
                // 操作按钮
                actionView
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Timeline Indicator
    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            // 蓝色圆点
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
            
            // 连接线（如果不是最后一个）
            if !isLast {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 2)
                    .frame(minHeight: 50)
                    .padding(.top, 4)
            }
        }
        .frame(width: 10)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center, spacing: 8) {
            // 时间戳
            Text(item.createdAt.timeAgoDisplay())
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            // 标签
            if let tag = item.extractedTag {
                TagView(tag: tag)
            } else {
                // 根据类型显示不同的标签
                let tagName = type == .link ? "Design" : type.name
                TagView(tag: tagName)
            }
            
            // 右侧图标（可选）
            Image(systemName: "brain")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Action View
    private var actionView: some View {
        HStack {
            Spacer()
            CompleteButton(
                type: self.type,
                isCompleted: $isCompleted,
                action: handleComplete
            )
        }
    }
    
    // MARK: - Actions
    private func handleComplete() {
        // 复制内容到剪贴板
        item.content.copyToClipboard()
        
        // 更新本地状态
        isCompleted = true
        
        // 更新数据模型
        item.isCompleted = true
        item.completedAt = Date()
        
        // 保存到数据库
        do {
            try modelContext.save()
        } catch {
            print("Failed to save completion status: \(error.localizedDescription)")
            // 如果保存失败，回滚本地状态
            isCompleted = false
        }
    }
}

// MARK: - Tag View
private struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag.hasPrefix("#") ? tag : "#\(tag)")
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.6))
            .cornerRadius(6)
    }
}

// MARK: - Complete Button
private struct CompleteButton: View {
    let type: ReadingCardModel.ReadingCardType
    @Binding var isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if type == .image {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .disabled(isCompleted)
    }
}

#Preview {
    VStack(spacing: 0) {
        TimelineCardView(item: ReadingCardModel.sampleCards()[0], isLast: false)
        TimelineCardView(item: ReadingCardModel.sampleCards()[1], isLast: true)
    }
    .padding()
    .background(Color(white: 0.95))
}

