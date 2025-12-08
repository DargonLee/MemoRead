//
//  AIModel.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import Foundation

struct AIModel: Identifiable, Codable {
    let id: UUID
    var name: String
    var provider: String
    var apiKey: String
    var baseURL: String
    var isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        provider: String,
        apiKey: String = "",
        baseURL: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.isDefault = isDefault
    }
    
    // MARK: - Preset Models
    static let deepSeek = AIModel(
        name: "DeepSeek",
        provider: "DeepSeek",
        baseURL: "https://api.deepseek.com/v1",
        isDefault: true
    )
    
    static let openAI = AIModel(
        name: "OpenAI",
        provider: "OpenAI",
        baseURL: "https://api.openai.com/v1"
    )
    
    static let claude = AIModel(
        name: "Claude",
        provider: "Anthropic",
        baseURL: "https://api.anthropic.com/v1"
    )
    
    static let defaultModels: [AIModel] = [.deepSeek, .openAI, .claude]
}

