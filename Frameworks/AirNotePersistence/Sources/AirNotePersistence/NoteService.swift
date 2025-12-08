import Foundation
import CoreData

public class NoteService: ObservableObject {
    private let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Create
    public func createNote(title: String, content: String, tag: String? = nil, imageUrl: String? = nil, link: String? = nil) {
        let newNote = NoteEntity(context: context)
        newNote.id = UUID().uuidString
        newNote.title = title
        newNote.content = content
        newNote.tag = tag
        newNote.imageUrl = imageUrl
        newNote.link = link
        newNote.updatedAt = Date()
        newNote.isSynced = false // CloudKit 会在后台处理，但在本地逻辑上它是新的
        
        saveContext()
    }

    // MARK: - Update
    public func updateNote(_ note: NoteEntity, content: String? = nil, summary: String? = nil) {
        if let content = content {
            note.content = content
        }
        if let summary = summary {
            note.summary = summary
        }
        note.updatedAt = Date()
        saveContext()
    }

    // MARK: - Delete
    public func deleteNote(_ note: NoteEntity) {
        context.delete(note)
        saveContext()
    }

    // MARK: - Save Helper
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
