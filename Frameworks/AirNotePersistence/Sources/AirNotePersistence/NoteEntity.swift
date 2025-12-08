import Foundation
import CoreData

@objc(NoteEntity)
public class NoteEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var content: String
    @NSManaged public var imageUrl: String?
    @NSManaged public var link: String?
    @NSManaged public var summary: String?
    @NSManaged public var tag: String?
    @NSManaged public var updatedAt: Date
    @NSManaged public var isSynced: Bool
}

extension NoteEntity {
    // 方便 SwiftUI 使用的 FetchRequest
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NoteEntity> {
        return NSFetchRequest<NoteEntity>(entityName: "NoteEntity")
    }
}

// 对应 Web 版 Note 接口的转换逻辑（可选）
extension NoteEntity {
    public var isValid: Bool {
        return !id.isEmpty
    }
}
