//
//  TimelineCardView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import SwiftUI
import SwiftData

struct TimelineCardView: View {
    @Environment(\.modelContext) private var modelContext
    let item: ReadingCardModel
    let isLast: Bool
    @State private var isSynced: Bool
    @State private var showSummarySheet = false
    @State private var summaryText: String = ""
    @State private var isGeneratingSummary = false
    private var type: ReadingCardModel.ReadingCardType
    
    // MARK: - Initialization
    init(item: ReadingCardModel, isLast: Bool = false) {
        self.item = item
        self.isLast = isLast
        _isSynced = State(initialValue: item.isSynced)
        self.type = ReadingCardModel.ReadingCardType(rawValue: item.type)!
    }
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: TimelineLayout.horizontalSpacing) {
            // 左侧时间线
            timelineIndicator
            
            // 右侧内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 1. 顶部：时间戳 + 状态图标
                headerView
                
                // 2. 白色卡片区域
                VStack(alignment: .leading, spacing: 16) {
                    ReadingCardContentView(item: item)
                    
                    // 3. 底部：标签 + 操作按钮
                    footerView
                }
                .padding(16)
                .background(TimelineStyle.cardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(TimelineStyle.listBackground)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                handleDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showSummarySheet) {
            SummarySheetView(
                content: item.content,
                summary: $summaryText,
                isGenerating: $isGeneratingSummary
            )
        }
        .onChange(of: item.isSynced) { _, newValue in
            isSynced = newValue
        }
    }
    
    // MARK: - Timeline Indicator
    private var timelineIndicator: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(TimelineStyle.accent)
                .frame(width: TimelineLayout.dotSize, height: TimelineLayout.dotSize)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .padding(.top, 4) // 对齐时间文本
            
            if !isLast {
                Rectangle()
                    .fill(TimelineStyle.line)
                    .frame(width: TimelineLayout.lineWidth)
                    .padding(.vertical, 4)
            } else {
                Spacer()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(item.createdAt.timeAgoDisplay())
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 10) {
                // 类型图标 (如果是链接或图片)
                if type != ReadingCardModel.ReadingCardType.text {
                    Image(systemName: type.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                // 同步/完成状态
                if isSynced {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green.opacity(0.8))
                } else {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
        }
        .padding(.trailing, 4)
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        HStack(alignment: .center) {
            // 标签
            HStack(spacing: 8) {
                if let tag = item.extractedTag {
                    Text("#\(tag)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                } else {
                    Text("#\(type.name)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 20) {
                AISummaryButton(action: handleAISummary)
                
                Button(action: {
                    item.content.copyToClipboard()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                Button(action: {
                    handleShare()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
    }
    
    // MARK: - Actions
    private func handleShare() {
        // 分享逻辑
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [item.content], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
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
    
    private func handleDelete() {
        #if os(iOS)
        let service = MultipeerSyncService.shared
        
        // 检查是否有连接的设备
        if service.hasConnectedPeers {
            // 有连接，立即同步删除
            let syncSuccess = service.syncCardDeletion(item.id)
            if syncSuccess {
                // 同步成功，直接删除
                modelContext.delete(item)
            } else {
                // 同步失败，标记为待删除
                item.pendingDeletion = true
            }
        } else {
            // 没有连接，标记为待删除，等待连接后同步
            item.pendingDeletion = true
        }
        #else
        // macOS 直接删除
        modelContext.delete(item)
        #endif
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete card: \(error.localizedDescription)")
        }
    }
}

// MARK: - Style & Layout
private enum TimelineStyle {
    static let accent = Color.blue
    static let line = Color.blue.opacity(0.3)
    
    static var cardBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(.windowBackgroundColor)
        #else
        return .white
        #endif
    }
    
    static var listBackground: Color {
        #if os(iOS)
        return Color(.systemGroupedBackground)
        #else
        return Color.clear
        #endif
    }
}

private enum TimelineLayout {
    static let horizontalSpacing: CGFloat = 16
    static let dotSize: CGFloat = 12
    static let lineWidth: CGFloat = 2
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
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundColor(.secondary)
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
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
#elseif os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
#endif
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

