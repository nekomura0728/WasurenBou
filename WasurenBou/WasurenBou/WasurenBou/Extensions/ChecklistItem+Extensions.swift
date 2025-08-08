//
//  ChecklistItem+Extensions.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import CoreData

extension ChecklistItem {
    convenience init(context: NSManagedObjectContext, title: String, order: Int16, checklist: Checklist) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.order = order
        self.createdAt = Date()
        self.isChecked = false
        self.checklist = checklist
    }
}