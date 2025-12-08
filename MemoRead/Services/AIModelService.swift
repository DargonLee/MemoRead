//
//  AIModelService.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import Foundation

class AIModelService {
    static let shared = AIModelService()
    
    private let modelsKey = "savedAIModels"
    private let defaultModelKey = "defaultAIModelId"
    
    private init() {}
    
    // MARK: - Model Management
    var savedModels: [AIModel] {
        get {
            guard let data = UserDefaults.standard.data(forKey: modelsKey),
                  let models = try? JSONDecoder().decode([AIModel].self, from: data),
                  !models.isEmpty else {
                // 首次使用时，初始化默认模型
                let defaultModels = AIModel.defaultModels
                if let data = try? JSONEncoder().encode(defaultModels) {
                    UserDefaults.standard.set(data, forKey: modelsKey)
                }
                return defaultModels
            }
            return models
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: modelsKey)
            }
        }
    }
    
    var defaultModel: AIModel? {
        get {
            guard let defaultIdString = UserDefaults.standard.string(forKey: defaultModelKey),
                  let defaultId = UUID(uuidString: defaultIdString) else {
                return savedModels.first { $0.isDefault } ?? savedModels.first
            }
            return savedModels.first { $0.id == defaultId }
        }
        set {
            if let model = newValue {
                UserDefaults.standard.set(model.id.uuidString, forKey: defaultModelKey)
            }
        }
    }
    
    func addModel(_ model: AIModel) {
        var models = savedModels
        // 如果设置为默认，取消其他模型的默认状态
        if model.isDefault {
            models = models.map { var m = $0; m.isDefault = false; return m }
        }
        models.append(model)
        savedModels = models
    }
    
    func updateModel(_ model: AIModel) {
        var models = savedModels
        if let index = models.firstIndex(where: { $0.id == model.id }) {
            // 如果设置为默认，取消其他模型的默认状态
            if model.isDefault {
                models = models.map { var m = $0; m.isDefault = false; return m }
            }
            models[index] = model
            savedModels = models
        }
    }
    
    func deleteModel(_ model: AIModel) {
        var models = savedModels
        models.removeAll { $0.id == model.id }
        savedModels = models
    }
    
    func setDefaultModel(_ model: AIModel) {
        var models = savedModels
        models = models.map { var m = $0; m.isDefault = ($0.id == model.id); return m }
        savedModels = models
        defaultModel = model
    }
    
    // MARK: - Connection Test
    func testConnection(for model: AIModel, completion: @escaping (Result<String, Error>) -> Void) {
        guard !model.apiKey.isEmpty else {
            completion(.failure(AIModelError.missingAPIKey))
            return
        }
        
        // 根据不同的 provider 使用不同的测试端点
        let testURL: String
        let testMethod: String
        let testBody: [String: Any]
        
        switch model.provider {
        case "DeepSeek":
            testURL = "\(model.baseURL)/chat/completions"
            testMethod = "POST"
            testBody = [
                "model": "deepseek-chat",
                "messages": [
                    ["role": "user", "content": "Hello"]
                ],
                "max_tokens": 10
            ]
        case "OpenAI":
            testURL = "\(model.baseURL)/chat/completions"
            testMethod = "POST"
            testBody = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    ["role": "user", "content": "Hello"]
                ],
                "max_tokens": 10
            ]
        case "Anthropic":
            testURL = "\(model.baseURL)/messages"
            testMethod = "POST"
            testBody = [
                "model": "claude-3-haiku-20240307",
                "max_tokens": 10,
                "messages": [
                    ["role": "user", "content": "Hello"]
                ]
            ]
        default:
            testURL = "\(model.baseURL)/chat/completions"
            testMethod = "POST"
            testBody = [
                "model": "default",
                "messages": [
                    ["role": "user", "content": "Hello"]
                ],
                "max_tokens": 10
            ]
        }
        
        guard let url = URL(string: testURL) else {
            completion(.failure(AIModelError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = testMethod
        request.setValue("Bearer \(model.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if model.provider == "Anthropic" {
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(AIModelError.invalidResponse))
                return
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                completion(.success("连接成功"))
            } else {
                let errorMessage = "连接失败: HTTP \(httpResponse.statusCode)"
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? [String: Any],
                   let message = errorMsg["message"] as? String {
                    completion(.failure(AIModelError.apiError(message)))
                } else {
                    completion(.failure(AIModelError.apiError(errorMessage)))
                }
            }
        }.resume()
    }
}

enum AIModelError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key 不能为空"
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .apiError(let message):
            return message
        }
    }
}

