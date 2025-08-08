//
//  Reminder+Extensions.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/06.
//

import Foundation
import CoreData

// MARK: - Reminder Entity Extensions
extension Reminder {
    convenience init(context: NSManagedObjectContext, title: String, scheduledTime: Date) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.scheduledTime = scheduledTime
        self.isCompleted = false
        self.createdAt = Date()
        self.reminderType = ReminderType.once.rawValue
    }
    
    var reminderTypeEnum: ReminderType {
        get {
            return ReminderType(rawValue: reminderType ?? "once") ?? .once
        }
        set {
            reminderType = newValue.rawValue
        }
    }
    
    var notificationIds: [String] {
        get {
            guard let data = notificationIdentifiers else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            notificationIdentifiers = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Reminder Type Enum
enum ReminderType: String, CaseIterable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    
    var displayName: String {
        switch self {
        case .once: return "一回のみ"
        case .daily: return "毎日"
        case .weekly: return "毎週"
        }
    }
}