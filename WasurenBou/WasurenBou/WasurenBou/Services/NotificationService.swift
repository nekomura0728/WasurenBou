//
//  NotificationService.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/06.
//

import Foundation
import UserNotifications
import UIKit
import CoreData
import SwiftUI

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    @AppStorage("escalationInterval") private var escalationInterval: Double = 300
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert])
            await MainActor.run {
                self.isAuthorized = granted
            }
            checkAuthorizationStatus()
            
            if granted {
            } else {
            }
        } catch {
        }
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Notifications
    
    func scheduleReminderNotifications(for reminder: Reminder) {
        guard let _ = reminder.scheduledTime,
              let _ = reminder.title,
              let reminderId = reminder.id?.uuidString else {
            return
        }
        
        // 既存の通知をクリア
        cancelNotifications(for: reminderId)
        
        // エスカレーション通知をスケジュール
        scheduleEscalatingNotifications(for: reminder)
    }
    
    private func scheduleEscalatingNotifications(for reminder: Reminder) {
        guard let reminderId = reminder.id?.uuidString,
              let title = reminder.title,
              let scheduledTime = reminder.scheduledTime else {
            return
        }
        // ユーザー設定の間隔を反映（秒）
        let interval = max(60, Int(escalationInterval))
        let steps = [0, interval, interval * 2, interval * 3]
        var scheduledIds: [String] = []
        
        for (index, delay) in steps.enumerated() {
            let notificationTime = scheduledTime.addingTimeInterval(TimeInterval(delay))
            if notificationTime <= Date() { continue }
            
            let notificationId = "\(reminderId)_\(index)"
            scheduledIds.append(notificationId)
            
            let content = UNMutableNotificationContent()
            content.title = NotificationLevel.level(for: index).title
            content.body = title
            content.badge = NSNumber(value: getPendingRemindersCount())
            content.categoryIdentifier = "REMINDER_CATEGORY"
            content.userInfo = [
                "reminderId": reminderId,
                "escalationLevel": index,
                "reminderTitle": title
            ]
            
            // 深夜帯（22:00-7:00）は音を抑制
            let hour = Calendar.current.component(.hour, from: notificationTime)
            let isNightTime = (hour >= 22 || hour < 7)
            let level = NotificationLevel.level(for: index)
            if isNightTime {
                content.sound = nil
            } else {
                if level == .critical {
                    content.sound = UNNotificationSound.defaultCritical
                    content.interruptionLevel = .critical
                } else {
                    content.sound = level.sound
                }
            }
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: notificationId,
                content: content,
                trigger: trigger
            )
            
            center.add(request) { _ in
                // Notification scheduled
            }
        }
        
        // Core Dataに通知IDを保存
        let context = PersistenceController.shared.container.viewContext
        reminder.notificationIds = scheduledIds
        do {
            try context.save()
        } catch {
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotifications(for reminderId: String) {
        // 既知のID（エスカレーション + スヌーズ）
        var ids = (0..<4).map { "\(reminderId)_\($0)" }
        ids.append("\(reminderId)_snooze")
        
        // Core Dataに保存済みのIDも統合して確実にキャンセル
        let context = PersistenceController.shared.container.viewContext
        if let uuid = UUID(uuidString: reminderId) {
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            if let reminder = try? context.fetch(request).first {
                ids.append(contentsOf: reminder.notificationIds)
                reminder.notificationIds = []
                try? context.save()
            }
        }
        
        let uniqueIds = Array(Set(ids))
        center.removePendingNotificationRequests(withIdentifiers: uniqueIds)
        center.removeDeliveredNotifications(withIdentifiers: uniqueIds)
        
        
        // バッジ数を更新
        updateBadgeCount()
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        // バッジをクリア
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // MARK: - Badge Management
    
    private func getPendingRemindersCount() -> Int {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        
        // 今日以降の未完了のリマインダーのみカウント
        let startOfToday = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "isCompleted == NO AND scheduledTime >= %@", startOfToday as CVarArg)
        
        do {
            let count = try context.count(for: request)
            return count
        } catch {
            return 0
        }
    }
    
    func updateBadgeCount() {
        let count = getPendingRemindersCount()
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        // リマインダー用アクション
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "完了",
            options: [.foreground]
        )
        
        let snoozeMinutes = max(1, Int(escalationInterval / 60))
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "\(snoozeMinutes)分後に再通知",
            options: []
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER_CATEGORY",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // チェックリストリマインダー用アクション
        let viewChecklistAction = UNNotificationAction(
            identifier: "VIEW_CHECKLIST_ACTION",
            title: "チェックリストを開く",
            options: [.foreground]
        )
        
        let checklistReminderCategory = UNNotificationCategory(
            identifier: "CHECKLIST_REMINDER",
            actions: [viewChecklistAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        center.setNotificationCategories([reminderCategory, checklistReminderCategory])
    }
}

// MARK: - Notification Levels

enum NotificationLevel {
    case initial
    case reminder  
    case urgent
    case critical
    
    static func level(for index: Int) -> NotificationLevel {
        switch index {
        case 0: return .initial
        case 1: return .reminder
        case 2: return .urgent
        default: return .critical
        }
    }
    
    var title: String {
        switch self {
        case .initial: return "📝 リマインダー"
        case .reminder: return "🔔 リマインダー（再通知）"
        case .urgent: return "⚠️ 重要なリマインダー"
        case .critical: return "🚨 緊急リマインダー"
        }
    }
    
    var sound: UNNotificationSound {
        switch self {
        case .initial: return .default
        case .reminder: return .default
        case .urgent:
            if #available(iOS 17.0, *) {
                return .defaultRingtone
            } else {
                return .default
            }
        case .critical: return .defaultCritical
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    // フォアグラウンドで通知を受信した場合
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // 通知をタップした場合、または通知アクションを実行した場合
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let notificationType = userInfo["type"] as? String ?? "reminder"
        
        if notificationType == "checklist_reminder" {
            // チェックリストリマインダーの処理
            Task { @MainActor in
                handleChecklistReminderResponse(response: response)
            }
        } else {
            // 通常のリマインダーの処理
            guard let reminderId = userInfo["reminderId"] as? String else {
                completionHandler()
                return
            }
            
            switch response.actionIdentifier {
            case "COMPLETE_ACTION":
                // リマインダーを完了にマーク
                Task { @MainActor in
                    handleCompleteAction(reminderId: reminderId)
                }
                
            case "SNOOZE_ACTION":
                // 5分後に再通知
                Task { @MainActor in
                    handleSnoozeAction(reminderId: reminderId, title: userInfo["reminderTitle"] as? String ?? "リマインダー")
                }
                
            case UNNotificationDefaultActionIdentifier:
                // 通知タップでアプリを開く
                break
                
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    private func handleChecklistReminderResponse(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        guard let checklistID = userInfo["checklistID"] as? String,
              let checklistTitle = userInfo["checklistTitle"] as? String else {
            return
        }
        
        switch response.actionIdentifier {
        case "VIEW_CHECKLIST_ACTION":
            // チェックリストを開くアクション
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenChecklistFromNotification"),
                    object: nil,
                    userInfo: [
                        "checklistID": checklistID,
                        "checklistTitle": checklistTitle
                    ]
                )
            }
            
        case UNNotificationDefaultActionIdentifier:
            // 通知タップでアプリを開く
            Task { @MainActor in
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenChecklistFromNotification"),
                    object: nil,
                    userInfo: [
                        "checklistID": checklistID,
                        "checklistTitle": checklistTitle
                    ]
                )
            }
            
        default:
            break
        }
    }
    
    private func handleCompleteAction(reminderId: String) {
        // Core Dataからリマインダーを検索して完了にマーク
        let context = PersistenceController.shared.container.viewContext
        
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        if let uuid = UUID(uuidString: reminderId) {
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        } else {
            return
        }
        
        do {
            let reminders = try context.fetch(request)
            if let reminder = reminders.first {
                reminder.isCompleted = true
                reminder.completedAt = Date()
                try context.save()
                
                // 残りの通知をキャンセル
                cancelNotifications(for: reminderId)
                
                // アプリに完了を通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("ReminderCompletedFromNotification"),
                    object: nil,
                    userInfo: ["reminderId": reminderId]
                )
                
            }
        } catch {
        }
    }
    
    private func handleSnoozeAction(reminderId: String, title: String) {
        // 5分後に再通知をスケジュール
        let snoozeTime = Date().addingTimeInterval(300) // 5分後
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 スヌーズリマインダー"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = "REMINDER_CATEGORY"
        content.userInfo = ["reminderId": reminderId, "reminderTitle": title]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: snoozeTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(reminderId)_snooze",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { _ in
            // Snooze notification scheduled
        }
    }
}