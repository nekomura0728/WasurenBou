//
//  Checklist+ReminderExtensions.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import CoreData

extension Checklist {
    
    // MARK: - Reminder Properties
    
    var reminderTime: Date {
        get {
            let calendar = Calendar.current
            let hour = Int(reminderHour)
            let minute = Int(reminderMinute)
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        }
        set {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            reminderHour = Int16(components.hour ?? 9)
            reminderMinute = Int16(components.minute ?? 0)
        }
    }
    
    var reminderDays: Set<Int> {
        get {
            guard let data = reminderRepeatDays else { return [] }
            do {
                let days = try JSONDecoder().decode(Set<Int>.self, from: data)
                return days
            } catch {
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                reminderRepeatDays = data
            } catch {
                reminderRepeatDays = nil
            }
        }
    }
    
    var scheduledNotificationIdentifiers: [String] {
        get {
            guard let data = reminderIdentifiers else { return [] }
            do {
                let identifiers = try JSONDecoder().decode([String].self, from: data)
                return identifiers
            } catch {
                return []
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                reminderIdentifiers = data
            } catch {
                reminderIdentifiers = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func updateReminderSettings(
        enabled: Bool,
        time: Date,
        isRepeating: Bool,
        repeatDays: Set<Int>
    ) {
        reminderEnabled = enabled
        reminderTime = time
        reminderIsRepeating = isRepeating
        self.reminderDays = repeatDays
    }
    
    func hasValidReminderSettings() -> Bool {
        return reminderEnabled && (
            !reminderIsRepeating || 
            (reminderIsRepeating && !reminderDays.isEmpty)
        )
    }
    
    func getReminderDescription() -> String {
        guard reminderEnabled else { return "リマインダーなし" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: reminderTime)
        
        if reminderIsRepeating && !reminderDays.isEmpty {
            let weekdays = [
                (1, "日"), (2, "月"), (3, "火"), (4, "水"),
                (5, "木"), (6, "金"), (7, "土")
            ]
            let dayNames = reminderDays.sorted().compactMap { dayNum in
                weekdays.first { $0.0 == dayNum }?.1
            }
            return "毎週\(dayNames.joined(separator: "・"))の\(timeString)"
        } else if reminderIsRepeating {
            return "毎日\(timeString)"
        } else {
            return "1回のみ\(timeString)"
        }
    }
}