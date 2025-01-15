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
            // Consider logging the error for debugging purposes
            print("Error creating ModelContainer: \(error)")
            return nil // Return nil to avoid fatalError and allow graceful failure
        }
    }
}

