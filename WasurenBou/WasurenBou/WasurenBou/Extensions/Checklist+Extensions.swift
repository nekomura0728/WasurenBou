//
//  Checklist+Extensions.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import CoreData

extension Checklist {
    convenience init(context: NSManagedObjectContext, title: String, emoji: String) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.createdAt = Date()
        self.isLocationBased = false
    }
    
    var itemsArray: [ChecklistItem] {
        let set = items as? Set<ChecklistItem> ?? []
        return set.sorted { $0.order < $1.order }
    }
    
    var completionPercentage: Double {
        let total = itemsArray.count
        guard total > 0 else { return 0 }
        
        let completed = itemsArray.filter { $0.isChecked }.count
        return Double(completed) / Double(total)
    }
    
    var isCompleted: Bool {
        return !itemsArray.isEmpty && itemsArray.allSatisfy { $0.isChecked }
    }
}