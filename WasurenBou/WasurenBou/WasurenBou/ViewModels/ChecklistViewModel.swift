//
//  ChecklistViewModel.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import CoreData
import Combine
import UserNotifications

@MainActor
class ChecklistViewModel: ObservableObject {
    @Published var checklists: [Checklist] = []
    @Published var selectedChecklist: Checklist?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // プレミアム機能
    @Published var isPremium = false
    private let storeKitService = StoreKitService.shared
    
    private let persistenceController: PersistenceController
    private let errorService = ErrorHandlingService.shared
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private let lastResetKeyPrefix = "checklist_last_reset_"
    
    private func todayKey() -> String {
        let df = DateFormatter()
        df.calendar = Calendar.current
        df.locale = Locale.current
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        setupNotificationObservers()
        loadPremiumStatus()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadChecklists()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadPremiumStatus() {
        isPremium = storeKitService.isPremiumPurchased
        
        // StoreKitサービスの購入状態を監視
        storeKitService.$purchasedProductIDs
            .sink { [weak self] _ in
                self?.isPremium = self?.storeKitService.isPremiumPurchased ?? false
            }
            .store(in: &cancellables)
        
        // UserDefaultsの変更も監視（デバッグ用の強制ONトグルに対応）
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                let premium = UserDefaults.standard.bool(forKey: "isPremium")
                if self.isPremium != premium {
                    self.isPremium = premium || self.storeKitService.isPremiumPurchased
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Auto Reset (Daily)
    func autoResetIfNeeded(for checklist: Checklist) {
        guard let checklistId = checklist.id?.uuidString else { return }
        let key = lastResetKeyPrefix + checklistId
        let last = UserDefaults.standard.string(forKey: key)
        let today = todayKey()
        guard last != today else { return }
        
        // 当日初回アクセス → すべて未チェックに
        let context = persistenceController.container.viewContext
        var changed = false
        for item in checklist.itemsArray where item.isChecked {
            item.isChecked = false
            changed = true
        }
        if changed {
            do { try context.save() } catch {
                errorService.handle(AppError.coreDataError(error.localizedDescription), context: "日次リセット")
            }
        }
        UserDefaults.standard.set(today, forKey: key)
    }
    
    // まとめて適用（一覧読み込み後に呼べる）
    private func applyAutoResetIfNeeded() {
        for checklist in checklists {
            autoResetIfNeeded(for: checklist)
        }
        // リセット後の状態反映
        objectWillChange.send()
    }
    
    // MARK: - Manual Reset
    func resetChecklistItems(_ checklist: Checklist) {
        let context = persistenceController.container.viewContext
        for item in checklist.itemsArray where item.isChecked {
            item.isChecked = false
        }
        do {
            try context.save()
            if let checklistId = checklist.id?.uuidString {
                UserDefaults.standard.set(todayKey(), forKey: lastResetKeyPrefix + checklistId)
            }
            HapticFeedback.notification(.success)
        } catch {
            errorService.handle(AppError.coreDataError(error.localizedDescription), context: "手動リセット")
        }
        
        // 画面更新
        objectWillChange.send()
    }
    
    // MARK: - Data Loading
    
    func loadChecklists() async {
        isLoading = true
        defer { isLoading = false }
        
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Checklist> = Checklist.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Checklist.lastUsed, ascending: false),
            NSSortDescriptor(keyPath: \Checklist.createdAt, ascending: false)
        ]
        
        do {
            checklists = try context.fetch(request)
            // 日付変更時の自動リセット適用
            applyAutoResetIfNeeded()
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストの読み込み"
            )
            errorMessage = error.localizedDescription
        }
    }
    
    func loadChecklists() {
        Task {
            await loadChecklists()
        }
    }
    
    // MARK: - Checklist Operations
    
    func createChecklist(title: String, emoji: String = "📋") {
        let context = persistenceController.container.viewContext
        let checklist = Checklist(context: context, title: title, emoji: emoji)
        
        // デフォルトアイテムを追加
        addDefaultItems(to: checklist, context: context)
        
        do {
            try context.save()
            HapticFeedback.notification(.success)
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストの作成"
            )
        }
    }
    
    func deleteChecklist(_ checklist: Checklist) {
        let context = persistenceController.container.viewContext
        context.delete(checklist)
        
        do {
            try context.save()
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストの削除"
            )
        }
    }
    
    func selectChecklist(_ checklist: Checklist) {
        selectedChecklist = checklist
        
        // 最終使用日を更新
        let context = persistenceController.container.viewContext
        checklist.lastUsed = Date()
        
        do {
            try context.save()
        } catch {
        }
    }
    
    // MARK: - Checklist Item Operations
    
    func toggleItem(_ item: ChecklistItem) {
        let context = persistenceController.container.viewContext
        item.isChecked.toggle()
        
        do {
            try context.save()
            
            // 完了時のハプティックフィードback
            if item.isChecked {
                HapticFeedback.impact(.light)
                
                // 全て完了した場合の特別な演出
                if let checklist = item.checklist, checklist.isCompleted {
                    HapticFeedback.notification(.success)
                }
            }
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストアイテムのトグル"
            )
        }
    }
    
    func addItem(to checklist: Checklist, title: String) {
        let context = persistenceController.container.viewContext
        let maxOrder = checklist.itemsArray.map(\.order).max() ?? -1
        let newItem = ChecklistItem(context: context, title: title, order: maxOrder + 1, checklist: checklist)
        
        do {
            try context.save()
            
            // 即座にUIを更新
            objectWillChange.send()
            
            // データ再読み込み
            Task { @MainActor in
                await loadChecklists()
            }
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストアイテムの追加"
            )
        }
    }
    
    func deleteItem(_ item: ChecklistItem) {
        let context = persistenceController.container.viewContext
        context.delete(item)
        
        do {
            try context.save()
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストアイテムの削除"
            )
        }
    }
    
    // MARK: - GPS Features (Previously Premium Only)
    
    func enableLocationReminder(for checklist: Checklist, locationName: String, latitude: Double, longitude: Double, radius: Double = 100.0) {
        // プレミアム制限撤廃
        let context = persistenceController.container.viewContext
        checklist.isLocationBased = true
        checklist.locationName = locationName
        checklist.latitude = latitude
        checklist.longitude = longitude
        checklist.radius = radius
        
        do {
            try context.save()
            if let id = checklist.id?.uuidString {
                LocationService.shared.startMonitoring(
                    checklistID: id,
                    title: checklist.title ?? "チェックリスト",
                    latitude: latitude,
                    longitude: longitude,
                    radius: radius
                )
            }
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "位置リマインダーの有効化"
            )
        }
    }
    
    func disableLocationReminder(for checklist: Checklist) {
        let context = persistenceController.container.viewContext
        checklist.isLocationBased = false
        checklist.locationName = nil
        
        do {
            try context.save()
            if let id = checklist.id?.uuidString {
                LocationService.shared.stopMonitoringForChecklist(checklistID: id)
            }
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "位置リマインダーの無効化"
            )
        }
    }
    
    // MARK: - Premium Features
    
    func purchasePremium() async {
        // デモ用の簡易購入処理
        await storeKitService.loadProducts()
        let success = await storeKitService.purchasePremium()
        
        if success {
            isPremium = true
            HapticFeedback.notification(.success)
        }
    }
    
    // デモ用の購入メソッド（開発中のため）
    func purchasePremiumSync() {
        Task {
            await purchasePremium()
        }
    }
    
    // MARK: - Checklist Reminder Operations
    
    func saveReminderSettings(
        for checklist: Checklist,
        enabled: Bool,
        time: Date,
        isRepeating: Bool,
        repeatDays: Set<Int>
    ) {
        let context = persistenceController.container.viewContext
        
        // 既存の通知をキャンセル
        cancelScheduledNotifications(for: checklist)
        
        // 新しい設定を保存
        checklist.updateReminderSettings(
            enabled: enabled,
            time: time,
            isRepeating: isRepeating,
            repeatDays: repeatDays
        )
        
        do {
            try context.save()
            
            // 有効な場合は新しい通知をスケジュール
            if enabled {
                Task {
                    await scheduleChecklistReminders(for: checklist)
                }
            }
            
        } catch {
            errorService.handle(
                AppError.coreDataError(error.localizedDescription),
                context: "チェックリストリマインダー設定の保存"
            )
        }
    }
    
    private func cancelScheduledNotifications(for checklist: Checklist) {
        let identifiers = checklist.scheduledNotificationIdentifiers
        if !identifiers.isEmpty {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            checklist.scheduledNotificationIdentifiers = []
        }
    }
    
    private func scheduleChecklistReminders(for checklist: Checklist) async {
        guard checklist.hasValidReminderSettings() else { return }
        
        await notificationService.requestNotificationPermission()
        
        var notificationIdentifiers: [String] = []
        let title = "\(checklist.title ?? "チェックリスト")の確認をお忘れなく！"
        let body = "未完了のアイテムがあります。確認してみませんか？"
        
        let calendar = Calendar.current
        let hour = Int(checklist.reminderHour)
        let minute = Int(checklist.reminderMinute)
        
        if checklist.reminderIsRepeating {
            if checklist.reminderDays.isEmpty {
                // 毎日繰り返し
                let identifier = "checklist_daily_\(checklist.id?.uuidString ?? UUID().uuidString)"
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                content.categoryIdentifier = "CHECKLIST_REMINDER"
                content.userInfo = [
                    "type": "checklist_reminder",
                    "checklistID": checklist.id?.uuidString ?? "",
                    "checklistTitle": checklist.title ?? "チェックリスト"
                ]
                
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    notificationIdentifiers.append(identifier)
                } catch {
                }
            } else {
                // 指定曜日に繰り返し
                for dayNumber in checklist.reminderDays {
                    let identifier = "checklist_weekly_\(checklist.id?.uuidString ?? UUID().uuidString)_day\(dayNumber)"
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default
                    content.categoryIdentifier = "CHECKLIST_REMINDER"
                    content.userInfo = [
                        "type": "checklist_reminder",
                        "checklistID": checklist.id?.uuidString ?? "",
                        "checklistTitle": checklist.title ?? "チェックリスト"
                    ]
                    
                    var dateComponents = DateComponents()
                    dateComponents.weekday = dayNumber
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                        notificationIdentifiers.append(identifier)
                    } catch {
                    }
                }
            }
        } else {
            // 1回のみの通知
            let identifier = "checklist_once_\(checklist.id?.uuidString ?? UUID().uuidString)"
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "CHECKLIST_REMINDER"
            content.userInfo = [
                "type": "checklist_reminder",
                "checklistID": checklist.id?.uuidString ?? "",
                "checklistTitle": checklist.title ?? "チェックリスト"
            ]
            
            let reminderDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, reminderDate.timeIntervalSinceNow), repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                notificationIdentifiers.append(identifier)
            } catch {
            }
        }
        
        // 通知IDを保存
        checklist.scheduledNotificationIdentifiers = notificationIdentifiers
        let context = persistenceController.container.viewContext
        do {
            try context.save()
        } catch {
        }
    }
    
    // MARK: - Helper Methods
    
    private func addDefaultItems(to checklist: Checklist, context: NSManagedObjectContext) {
        // チェックリストのタイトルに基づいてデフォルトアイテムを追加
        var defaultItems: [String] = []
        
        let title = checklist.title?.lowercased() ?? ""
        if title.contains("外出") || title.contains("出かける") {
            defaultItems = ["スマホ", "財布", "家の鍵", "ハンカチ・ティッシュ"]
        } else if title.contains("旅行") || title.contains("出張") {
            defaultItems = ["パスポート・身分証", "チケット", "充電器", "着替え"]
        } else if title.contains("仕事") || title.contains("会社") {
            defaultItems = ["ノートPC", "資料", "名刺", "筆記用具"]
        } else {
            // 汎用的なアイテム
            defaultItems = ["アイテム1", "アイテム2", "アイテム3"]
        }
        
        for (index, itemTitle) in defaultItems.enumerated() {
            _ = ChecklistItem(context: context, title: itemTitle, order: Int16(index), checklist: checklist)
        }
    }
}

// MARK: - Premium Purchase Error
enum PurchaseError: Error {
    case notAvailable
    case purchaseFailed
    case cancelled
    
    var localizedDescription: String {
        switch self {
        case .notAvailable:
            return "購入機能が利用できません"
        case .purchaseFailed:
            return "購入に失敗しました"
        case .cancelled:
            return "購入がキャンセルされました"
        }
    }
}