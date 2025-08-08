//
//  ReminderTemplate+Extensions.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/06.
//

import Foundation
import CoreData

// MARK: - ReminderTemplate Entity Extensions
extension ReminderTemplate {
    convenience init(context: NSManagedObjectContext, title: String, emoji: String) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.usageCount = 0
        self.lastUsed = Date()
    }
    
    func incrementUsage() {
        usageCount += 1
        lastUsed = Date()
    }
}