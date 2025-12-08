import CoreData
import CloudKit

public class PersistenceController {
    public static let shared = PersistenceController()

    public let container: NSPersistentCloudKitContainer

    private init(inMemory: Bool = false) {
        // 1. 编程式构建 Model，避免 SPM 资源加载问题
        let model = PersistenceController.createManagedObjectModel()
        
        // 2. 使用 Model 初始化 Container
        container = NSPersistentCloudKitContainer(name: "AirNoteModel", managedObjectModel: model)

        // 3. 配置持久化存储路径
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 默认配置支持 CloudKit
            // 注意：你需要在宿主 App 的 Capabilities 中开启 iCloud -> CloudKit
            let storeDescription = container.persistentStoreDescriptions.first
            storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        // 4. 加载存储
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // 5. 自动合并策略 (处理 iCloud 冲突的关键)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic Model Definition
    // 这里用代码定义了你在 Web 版中看到的字段结构
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        let noteEntity = NSEntityDescription()
        noteEntity.name = "NoteEntity"
        noteEntity.managedObjectClassName = NSStringFromClass(NoteEntity.self)
        
        // 属性定义
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .stringAttributeType
        idAttr.isOptional = false
        
        let titleAttr = NSAttributeDescription()
        titleAttr.name = "title"
        titleAttr.attributeType = .stringAttributeType
        titleAttr.isOptional = false
        titleAttr.defaultValue = ""
        
        let contentAttr = NSAttributeDescription()
        contentAttr.name = "content"
        contentAttr.attributeType = .stringAttributeType
        contentAttr.isOptional = false
        contentAttr.defaultValue = ""
        
        let updatedAtAttr = NSAttributeDescription()
        updatedAtAttr.name = "updatedAt"
        updatedAtAttr.attributeType = .dateAttributeType
        updatedAtAttr.isOptional = false
        
        let isSyncedAttr = NSAttributeDescription()
        isSyncedAttr.name = "isSynced"
        isSyncedAttr.attributeType = .booleanAttributeType
        isSyncedAttr.isOptional = false
        isSyncedAttr.defaultValue = true

        // 可选属性
        let imageUrlAttr = NSAttributeDescription()
        imageUrlAttr.name = "imageUrl"
        imageUrlAttr.attributeType = .stringAttributeType
        imageUrlAttr.isOptional = true
        
        let linkAttr = NSAttributeDescription()
        linkAttr.name = "link"
        linkAttr.attributeType = .stringAttributeType
        linkAttr.isOptional = true
        
        let summaryAttr = NSAttributeDescription()
        summaryAttr.name = "summary"
        summaryAttr.attributeType = .stringAttributeType
        summaryAttr.isOptional = true
        
        let tagAttr = NSAttributeDescription()
        tagAttr.name = "tag"
        tagAttr.attributeType = .stringAttributeType
        tagAttr.isOptional = true
        
        noteEntity.properties = [
            idAttr, titleAttr, contentAttr, updatedAtAttr, isSyncedAttr,
            imageUrlAttr, linkAttr, summaryAttr, tagAttr
        ]
        
        model.entities = [noteEntity]
        return model
    }
}
