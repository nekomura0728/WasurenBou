//
//  PersistenceController.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/06.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // プレビュー用のサンプルデータを作成
        let sampleReminder = Reminder(context: viewContext, title: "洗濯物を取り込む", scheduledTime: Date().addingTimeInterval(3600))
        let sampleTemplate = ReminderTemplate(context: viewContext, title: "薬を飲む", emoji: "💊")
        
        do {
            try viewContext.save()
        } catch {
            // プレビュー用なのでエラーは無視
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WasurenBou")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // iCloud同期の設定
        if !inMemory {
            container.persistentStoreDescriptions.forEach { storeDescription in
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                // 軽量マイグレーション
                storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
                storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            }
        }
        
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Core Data同期の設定
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}