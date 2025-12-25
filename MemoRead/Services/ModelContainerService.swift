//
//  ModelContainerService.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import SwiftUI
import SwiftData

class ModelContainerService {
    @AppStorage("enableAutoSync") private var enableAutoSync: Bool = false
    var modelContainer: ModelContainer?
    
    // MARK: - Shared Container
    static let shared = ModelContainerService()
    
    private init() {
        modelContainer = createModelContainer()
        if let container = modelContainer {
            print("✅ ModelContainer 创建成功: \(ObjectIdentifier(container))")
        } else {
            print("❌ ModelContainer 创建失败")
        }
    }
    
    // MARK: - Container Creation
    private func createModelContainer() -> ModelContainer? {
        let schema = Schema([
            ReadingCardModel.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: enableAutoSync ? .automatic : .none
        )
                
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            return container
        } catch {
            print("❌ 创建 ModelContainer 失败: \(error)")
            return nil
        }
    }
}

