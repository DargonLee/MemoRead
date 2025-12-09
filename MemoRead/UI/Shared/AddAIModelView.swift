//
//  AddAIModelView.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import SwiftUI

struct AddAIModelView: View {
    @Environment(\.dismiss) private var dismiss
    
    let model: AIModel?
    let onSave: (AIModel) -> Void
    let onCancel: () -> Void
    
    @State private var name: String = ""
    @State private var provider: String = "DeepSeek"
    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var isDefault: Bool = false
    
    private let providers = ["DeepSeek", "OpenAI", "Anthropic", "Custom"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Model Information")) {
                    TextField("Name", text: $name)
                    Picker("Provider", selection: $provider) {
                        ForEach(providers, id: \.self) { provider in
                            Text(provider).tag(provider)
                        }
                    }
                    .onChange(of: provider) { _, newValue in
                        updateBaseURL(for: newValue)
                    }
                }
                
                Section(header: Text("API Configuration")) {
                    SecureField("API Key", text: $apiKey)
                    TextField("Base URL", text: $baseURL)
#if os(iOS)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
#elseif os(macOS)
                        .disableAutocorrection(true)
#endif
                }
                
                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                }
                
                if let model = model {
                    Section {
                        Button(role: .destructive) {
                            AIModelService.shared.deleteModel(model)
                            dismiss()
                        } label: {
                            Label("Delete Model", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle(model == nil ? "Add AI Model" : "Edit AI Model")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveModel()
                    }
                    .disabled(name.isEmpty || apiKey.isEmpty || baseURL.isEmpty)
                }
            }
        }
        .onAppear {
            if let model = model {
                name = model.name
                provider = model.provider
                apiKey = model.apiKey
                baseURL = model.baseURL
                isDefault = model.isDefault
            } else {
                updateBaseURL(for: provider)
            }
        }
    }
    
    private func updateBaseURL(for provider: String) {
        switch provider {
        case "DeepSeek":
            baseURL = AIModel.deepSeek.baseURL
        case "OpenAI":
            baseURL = AIModel.openAI.baseURL
        case "Anthropic":
            baseURL = AIModel.claude.baseURL
        default:
            if baseURL.isEmpty {
                baseURL = "https://api.example.com/v1"
            }
        }
    }
    
    private func saveModel() {
        let newModel = AIModel(
            id: model?.id ?? UUID(),
            name: name,
            provider: provider,
            apiKey: apiKey,
            baseURL: baseURL,
            isDefault: isDefault
        )
        onSave(newModel)
    }
}

#Preview {
    AddAIModelView(
        model: nil,
        onSave: { _ in },
        onCancel: { }
    )
}


