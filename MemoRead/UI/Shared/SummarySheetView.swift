//
//  SummarySheetView.swift
//  MemoRead
//
//  Created by Harlan on 2025/12/25.
//

import SwiftUI

// MARK: - Summary Sheet View
struct SummarySheetView: View {
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

// MARK: - AI Summary Button
struct AISummaryButton: View {
    let action: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        Button(action: {
            isProcessing = true
            action()
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

