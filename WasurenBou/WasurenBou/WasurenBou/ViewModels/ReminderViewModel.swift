//
//  ReminderViewModel.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/06.
//

import Foundation
import CoreData
import Combine

@MainActor
class ReminderViewModel: ObservableObject {
    @Published var todayReminders: [Reminder] = []
    @Published var templates: [ReminderTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let persistenceController: PersistenceController
    private let notificationService = NotificationService.shared
    private let errorService = ErrorHandlingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Performance optimization
    private var loadingTask: Task<Void, Never>?
    private let cache = NSCache<NSString, NSArray>()
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB
        
        // Load data asynchronously
        Task {
            await loadData()
        }
        
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Core Data変更通知を監視 - debounce for performance
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
        
        // 通知からの完了アクション通知を監視
        NotificationCenter.default.publisher(for: NSNotification.Name("ReminderCompletedFromNotification"))
            .sink { [weak self] notification in
                Task { @MainActor in
                    if let reminderId = notification.userInfo?["reminderId"] as? String {
                        self?.handleReminderCompletedFromNotification(reminderId: reminderId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        // Cancel previous loading task
        loadingTask?.cancel()
        
        loadingTask = Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                async let reminders = loadTodayRemindersAsync()
                async let templates = loadTemplatesAsync()
                
                let (loadedReminders, loadedTemplates) = try await (reminders, templates)
                self.todayReminders = loadedReminders
                self.templates = loadedTemplates
            } catch {
                // Error is already handled in individual methods
            }
        }
    }
    
    private func loadTodayRemindersAsync() async throws -> [Reminder] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        
        // 今日の未完了のリマインダーのみ取得
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "isCompleted == NO AND scheduledTime >= %@ AND scheduledTime < %@", 
                                      startOfDay as CVarArg, endOfDay as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Reminder.scheduledTime, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Loading today's reminders"
            )
            return []
        }
    }
    
    private func loadTemplatesAsync() async throws -> [ReminderTemplate] {
        // Check cache first
        if let cached = cache.object(forKey: "templates") as? [ReminderTemplate] {
            return cached
        }
        
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ReminderTemplate> = ReminderTemplate.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ReminderTemplate.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \ReminderTemplate.lastUsed, ascending: false)
        ]
        request.fetchLimit = 10
        
        do {
            let templates = try context.fetch(request)
            // Cache the results
            cache.setObject(templates as NSArray, forKey: "templates")
            return templates
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Loading templates"
            )
            return []
        }
    }
    
    // MARK: - Reminder Operations
    
    func createReminder(title: String, scheduledTime: Date) {
        let context = persistenceController.container.viewContext
        let reminder = Reminder(context: context, title: title, scheduledTime: scheduledTime)
        
        do {
            try context.save()
            
            // 通知をスケジュール
            notificationService.scheduleReminderNotifications(for: reminder)
            
            // バッジ数を更新
            notificationService.updateBadgeCount()
            
            Task {
                await loadData()
            }
            
            // Haptic feedback for success
            HapticFeedback.notification(.success)
            
            print("✅ リマインダー作成完了: \(title) at \(scheduledTime)")
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Creating reminder"
            )
        }
    }
    
    func completeReminder(_ reminder: Reminder) {
        let context = persistenceController.container.viewContext
        reminder.isCompleted = true
        reminder.completedAt = Date()
        
        // 関連する通知をキャンセル
        if let reminderId = reminder.id?.uuidString {
            notificationService.cancelNotifications(for: reminderId)
        }
        
        do {
            try context.save()
            
            // バッジ数を更新
            notificationService.updateBadgeCount()
            
            Task {
                await loadData()
            }
            showCompletionMessage()
            
            // Haptic feedback for completion
            HapticFeedback.notification(.success)
            
            print("✅ リマインダー完了: \(reminder.title ?? "")")
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Completing reminder"
            )
        }
    }
    
    func deleteReminder(_ reminder: Reminder) {
        let context = persistenceController.container.viewContext
        
        // 関連する通知をキャンセル
        if let reminderId = reminder.id?.uuidString {
            notificationService.cancelNotifications(for: reminderId)
        }
        
        context.delete(reminder)
        
        do {
            try context.save()
            
            // バッジ数を更新
            notificationService.updateBadgeCount()
            
            Task {
                await loadData()
            }
            print("🗑️ リマインダー削除: \(reminder.title ?? "")")
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Deleting reminder"
            )
        }
    }
    
    // MARK: - Template Operations
    
    func createTemplate(title: String, emoji: String) {
        let context = persistenceController.container.viewContext
        _ = ReminderTemplate(context: context, title: title, emoji: emoji)
        
        do {
            try context.save()
            // Clear cache to force reload
            cache.removeObject(forKey: "templates")
            
            
            Task {
                await loadData()
            }
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Creating template"
            )
        }
    }
    
    func deleteTemplate(_ template: ReminderTemplate) {
        let context = persistenceController.container.viewContext
        context.delete(template)
        
        do {
            try context.save()
            // Clear cache to force reload
            cache.removeObject(forKey: "templates")
            
            
            Task {
                await loadData()
            }
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "Deleting template"
            )
        }
    }
    
    // MARK: - Voice Recognition Integration
    
    func processVoiceInput(_ text: String) -> String {
        // 音声入力のテキストを処理
        let processedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 音声入力から適切なテンプレートを検索して使用
        findAndUseMatchingTemplate(for: processedText)
        
        return processedText
    }
    
    private func findAndUseMatchingTemplate(for voiceText: String) {
        // 音声入力に基づいてテンプレートを検索・作成
        let lowerText = voiceText.lowercased()
        
        // よく使われる表現をテンプレート候補として判定
        let templateCandidates: [(keywords: [String], emoji: String, title: String)] = [
            (["薬", "飲む"], "💊", "薬を飲む"),
            (["洗濯", "取り込む", "干す"], "🧺", "洗濯物取り込む"),
            (["ゴミ", "出す"], "🗑️", "ゴミ出し"),
            (["電話", "母", "お母さん"], "📞", "母に電話"),
            (["買い物", "牛乳", "ミルク"], "🛒", "牛乳買う"),
            (["車", "エンジン", "チェック"], "🚗", "車のエンジンチェック")
        ]
        
        // マッチするテンプレートを探す
        for candidate in templateCandidates {
            if candidate.keywords.contains(where: { lowerText.contains($0) }) {
                // 既存テンプレートにない場合は新規作成
                if !templates.contains(where: { $0.title == candidate.title }) {
                    createTemplate(title: candidate.title, emoji: candidate.emoji)
                }
                break
            }
        }
    }
    
    // MARK: - User Experience
    
    private func showCompletionMessage() {
        // TODO: 完了時の褒めメッセージを実装
        print("素晴らしい！リマインダーを完了しました 🎉")
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Notification Actions
    
    private func handleReminderCompletedFromNotification(reminderId: String) {
        // 通知からリマインダーが完了された時の処理
        Task {
            await loadData()
        }
        showCompletionMessage()
        
        // Haptic feedback
        HapticFeedback.notification(.success)
        
        print("🔔 通知からリマインダー完了: \(reminderId)")
    }
}