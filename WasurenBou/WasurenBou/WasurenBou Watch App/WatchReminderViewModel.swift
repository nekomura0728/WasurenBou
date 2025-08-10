//
//  WatchReminderViewModel.swift
//  Remind!!! Watch App
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import SwiftUI
import WatchConnectivity
import CoreData

@MainActor
class WatchReminderViewModel: NSObject, ObservableObject {
    @Published var todayReminders: [Reminder] = []
    @Published var templates: [ReminderTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController = PersistenceController.shared
    private var session: WCSession = WCSession.default
    
    var todayRemindersCount: Int {
        todayReminders.count
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
        loadData()
    }
    
    // MARK: - Watch Connectivity Setup
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - Data Loading
    func loadData() {
        loadTodayReminders()
        loadTemplates()
    }
    
    private func loadTodayReminders() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        
        // 今日の未完了のリマインダーのみ取得
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(
            format: "isCompleted == NO AND scheduledTime >= %@ AND scheduledTime < %@",
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.scheduledTime, ascending: true)]
        
        do {
            todayReminders = try context.fetch(request)
        } catch {
            errorMessage = "Failed to load reminders: \(error.localizedDescription)"
        }
    }
    
    private func loadTemplates() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ReminderTemplate> = ReminderTemplate.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ReminderTemplate.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \ReminderTemplate.lastUsed, ascending: false)
        ]
        request.fetchLimit = 6 // Watch用に制限
        
        do {
            templates = try context.fetch(request)
        } catch {
            errorMessage = "Failed to load templates: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Reminder Operations
    func createReminder(title: String, scheduledTime: Date) {
        let context = persistenceController.container.viewContext
        let reminder = Reminder(context: context, title: title, scheduledTime: scheduledTime)
        
        if persistenceController.safeSave() {
            loadTodayReminders()
            
            // iPhoneに同期
            syncReminderToiPhone(reminder)
        } else {
            errorMessage = "リマインダーの作成に失敗しました"
        }
    }
    
    func completeReminder(_ reminder: Reminder) {
        let context = persistenceController.container.viewContext
        reminder.isCompleted = true
        reminder.completedAt = Date()
        
        if persistenceController.safeSave() {
            loadTodayReminders()
            
            // iPhoneに同期
            syncReminderCompletionToiPhone(reminder)
        } else {
            errorMessage = "リマインダーの完了に失敗しました"
        }
    }
    
    // MARK: - iPhone Sync
    private func syncReminderToiPhone(_ reminder: Reminder) {
        guard session.isReachable else { return }
        
        let reminderData: [String: Any] = [
            "action": "createReminder",
            "title": reminder.title ?? "",
            "scheduledTime": reminder.scheduledTime?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            "id": reminder.id?.uuidString ?? UUID().uuidString
        ]
        
        session.sendMessage(reminderData, replyHandler: nil) { error in
            Task { @MainActor in
                self.errorMessage = "同期エラー: \(error.localizedDescription)"
            }
        }
    }
    
    private func syncReminderCompletionToiPhone(_ reminder: Reminder) {
        guard session.isReachable else { return }
        
        let completionData: [String: Any] = [
            "action": "completeReminder",
            "id": reminder.id?.uuidString ?? ""
        ]
        
        session.sendMessage(completionData, replyHandler: nil) { error in
            Task { @MainActor in
                self.errorMessage = "同期エラー: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Request Data from iPhone
    func requestDataFromiPhone() {
        guard session.isReachable else { return }
        
        let request: [String: Any] = ["action": "requestData"]
        
        session.sendMessage(request, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleiPhoneDataResponse(reply)
            }
        }) { error in
            Task { @MainActor in
                self?.errorMessage = "データ要求エラー: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleiPhoneDataResponse(_ data: [String: Any]) {
        // iPhoneからのデータを処理
        if let remindersData = data["reminders"] as? [[String: Any]] {
            // リマインダーデータの同期処理
            // リマインダーデータを受信
        }
        
        if let templatesData = data["templates"] as? [[String: Any]] {
            // テンプレートデータの同期処理
            // テンプレートデータを受信
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchReminderViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.errorMessage = "Watch接続エラー: \(error.localizedDescription)"
                return
            }
            
            // アクティベーション後にiPhoneからデータを要求
            if activationState == .activated {
                self.requestDataFromiPhone()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleMessageFromiPhone(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleMessageFromiPhone(message)
            replyHandler(["status": "received"])
        }
    }
    
    private func handleMessageFromiPhone(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        
        switch action {
        case "reminderCreated":
            // iPhoneで作成されたリマインダーを反映
            loadTodayReminders()
            // iPhoneでリマインダーが作成されました
            
        case "reminderCompleted":
            // iPhoneで完了されたリマインダーを反映
            loadTodayReminders()
            // iPhoneでリマインダーが完了されました
            
        case "templatesUpdated":
            // テンプレートが更新された
            loadTemplates()
            // iPhoneでテンプレートが更新されました
            
        default:
            break
        }
    }
}

// MARK: - Watch Haptic Feedback
extension WatchReminderViewModel {
    func playHaptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    
    func playSuccess() {
        WKInterfaceDevice.current().play(.success)
    }
    
    func playFailure() {
        WKInterfaceDevice.current().play(.failure)
    }
}