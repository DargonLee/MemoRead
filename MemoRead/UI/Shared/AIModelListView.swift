//
//  AIModelListView.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import SwiftUI

struct AIModelListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var savedModels: [AIModel] = []
    @State private var showAddModelSheet = false
    @State private var editingModel: AIModel?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(savedModels) { model in
                    AIModelListRowView(
                        model: model,
                        isSelected: AIModelService.shared.defaultModel?.id == model.id,
                        onSelect: {
                            AIModelService.shared.setDefaultModel(model)
                            savedModels = AIModelService.shared.savedModels
                        },
                        onDelete: {
                            deleteModel(model)
                        }
                    )
                }
                .onDelete { indexSet in
                    deleteModels(at: indexSet)
                }
            }
            .navigationTitle("AI Models")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingModel = nil
                        showAddModelSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddModelSheet) {
                AddAIModelView(
                    model: editingModel,
                    onSave: { model in
                        if editingModel != nil {
                            AIModelService.shared.updateModel(model)
                        } else {
                            AIModelService.shared.addModel(model)
                        }
                        savedModels = AIModelService.shared.savedModels
                        editingModel = nil
                        showAddModelSheet = false
                    },
                    onCancel: {
                        editingModel = nil
                        showAddModelSheet = false
                    }
                )
            }
            .onAppear {
                savedModels = AIModelService.shared.savedModels
            }
        }
    }
    
    private func deleteModels(at offsets: IndexSet) {
        for index in offsets {
            let model = savedModels[index]
            AIModelService.shared.deleteModel(model)
        }
        savedModels = AIModelService.shared.savedModels
    }
    
    private func deleteModel(_ model: AIModel) {
        AIModelService.shared.deleteModel(model)
        savedModels = AIModelService.shared.savedModels
    }
}

struct AIModelListRowView: View {
    let model: AIModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isTesting = false
    @State private var testResult: String?
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(model.provider)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !model.baseURL.isEmpty {
                        Text(model.baseURL)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    if let result = testResult {
                        Text(result)
                            .font(.caption2)
                            .foregroundColor(result.contains("成功") ? .green : .red)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: testConnection) {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
#if os(macOS)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
#endif
    }
    
    private func testConnection() {
        isTesting = true
        testResult = nil
        
        AIModelService.shared.testConnection(for: model) { result in
            DispatchQueue.main.async {
                isTesting = false
                switch result {
                case .success(let message):
                    testResult = message
                case .failure(let error):
                    testResult = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AIModelListView()
}

