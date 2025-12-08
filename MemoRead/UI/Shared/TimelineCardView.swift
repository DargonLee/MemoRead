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
    @State private var showSummarySheet = false
    @State private var summaryText: String = ""
    @State private var isGeneratingSummary = false
    private var type: ReadingCardModel.ReadingCardType
    private var cardTag: String {
        if let tag = item.extractedTag {
            return tag
        }
        return type == .link ? "Design" : type.name
    }
    
    // MARK: - Initialization
    init(item: ReadingCardModel, isLast: Bool = false) {
        self.item = item
        self.isLast = isLast
        _isCompleted = State(initialValue: item.isCompleted)
        self.type = ReadingCardModel.ReadingCardType(rawValue: item.type)!
    }
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: TimelineLayout.horizontalSpacing) {
            // 左侧时间线
            timelineIndicator
            
            // 右侧内容区域
            VStack(alignment: .leading, spacing: TimelineLayout.sectionSpacing) {
                // 顶部：时间戳 + 标签 水平排列
                headerView
                
                // 中部：内容区域撑满
                ReadingCardContentView(item: item)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 底部：操作区域
                actionView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, TimelineLayout.horizontalPadding)
        .padding(.vertical, TimelineLayout.verticalPadding)
        .background(TimelineStyle.cardBackground)
        .sheet(isPresented: $showSummarySheet) {
            SummarySheetView(
                content: item.content,
                summary: $summaryText,
                isGenerating: $isGeneratingSummary
            )
        }
    }
    
    // MARK: - Timeline Indicator
    private var timelineIndicator: some View {
        TimelineIndicator(
            isLast: isLast,
            accent: TimelineStyle.accent,
            line: TimelineStyle.line
        )
        .frame(width: TimelineLayout.timelineWidth, alignment: .center)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 8) {
            Text(item.createdAt.timeAgoDisplay())
                .font(.caption)
                .foregroundColor(.primary)
            
            TagView(tag: cardTag)
            
            Spacer()
        }
    }
    
    // MARK: - Action View
    private var actionView: some View {
        HStack(spacing: 12) {
            Spacer()
            // AI总结按钮
            AISummaryButton(action: handleAISummary)
            // 复制按钮
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
    
    private func handleAISummary() {
        isGeneratingSummary = true
        showSummarySheet = true
        
        AISummaryService.shared.generateSummary(for: item.content) { result in
            DispatchQueue.main.async {
                isGeneratingSummary = false
                switch result {
                case .success(let summary):
                    summaryText = summary
                case .failure(let error):
                    summaryText = "生成总结时出错: \(error.localizedDescription)"
                }
            }
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
            .background(TimelineStyle.tagBackground)
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

// MARK: - Timeline Style & Layout
private enum TimelineStyle {
    static let accent = Color.blue
    static let line = Color.blue.opacity(0.3)
    static let tagBackground = Color.gray.opacity(0.6)
    static let cardBackground = Color(.systemBackground)
}

private enum TimelineLayout {
    static let horizontalSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 8
    static let timelineWidth: CGFloat = 12
    static let dotSize: CGFloat = 10
    static let lineWidth: CGFloat = 2
    static let lineMinHeight: CGFloat = 50
    static let lineTopPadding: CGFloat = 4
}

// MARK: - Timeline Indicator
private struct TimelineIndicator: View {
    let isLast: Bool
    let accent: Color
    let line: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(accent)
                .frame(width: TimelineLayout.dotSize, height: TimelineLayout.dotSize)
            
            if !isLast {
                Rectangle()
                    .fill(line)
                    .frame(width: TimelineLayout.lineWidth)
                    .frame(minHeight: TimelineLayout.lineMinHeight)
                    .padding(.top, TimelineLayout.lineTopPadding)
            }
        }
    }
}

// MARK: - AI Summary Button
private struct AISummaryButton: View {
    let action: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        Button(action: {
            isProcessing = true
            action()
            // 模拟处理完成后重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isProcessing = false
            }
        }) {
            Group {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .disabled(isProcessing)
    }
}

// MARK: - Summary Sheet View
private struct SummarySheetView: View {
    let content: String
    @Binding var summary: String
    @Binding var isGenerating: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 原文
                VStack(alignment: .leading, spacing: 8) {
                    Text("原文")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(content)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 200)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // AI总结
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AI总结")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if isGenerating {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(height: 100)
                    } else {
                        ScrollView {
                            Text(summary.isEmpty ? "点击生成总结" : summary)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                        .padding(12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AI总结")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        TimelineCardView(item: ReadingCardModel.sampleCards()[0], isLast: false)
        TimelineCardView(item: ReadingCardModel.sampleCards()[1], isLast: false)
        TimelineCardView(item: ReadingCardModel.sampleCards()[2], isLast: true)
    }
    .padding()
    .background(Color(white: 0.95))
}

