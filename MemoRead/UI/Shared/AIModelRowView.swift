//
//  AIModelRowView.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import SwiftUI

struct AIModelRowView: View {
    let model: AIModel
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isTesting = false
    @State private var testResult: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.name)
                            .font(.headline)
                        if isDefault {
                            Text("(Default)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    Text(model.provider)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !model.baseURL.isEmpty {
                        Text(model.baseURL)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: testConnection) {
                            Label("Test", systemImage: "network")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: onSetDefault) {
                        Image(systemName: isDefault ? "star.fill" : "star")
                            .foregroundColor(isDefault ? .yellow : .gray)
                    }
                    .disabled(isDefault)
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                }
            }
            
            if let result = testResult {
                Text(result)
                    .font(.caption)
                    .foregroundColor(result.contains("成功") ? .green : .red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
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

