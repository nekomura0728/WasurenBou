//
//  WasurenBouApp.swift
//  WasurenBou
//
//  Created by 前村　真之介 on 2025/08/06.
//

import SwiftUI

@main
struct WasurenBouApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationService)
                .environment(\.locale, determineAppLocale())
                .withErrorHandling()
                .onAppear {
                    // ロケール診断ログ（一時）
                    let preferred = Bundle.main.preferredLocalizations
                    let available = Bundle.main.localizations
                    let currentLang = Locale.current.identifier
                    
                    // Locale debugging
                    let currentLocale = Locale.current
                    let preferredLangs = Locale.preferredLanguages
                    let bundleLocalizations = Bundle.main.localizations
                    let bundlePreferred = Bundle.main.preferredLocalizations
                    
                    setupNotifications()
                    setupNotificationObservers()
                    Task {
                        await ConsentService.shared.requestATTIfNeeded()
                        await ConsentService.shared.requestGDPRIfNeeded()
                        AdMobService.shared.initialize()
                    }
                }
        }
    }
    
    private func setupNotifications() {
        // 通知カテゴリをセットアップ
        notificationService.setupNotificationCategories()
        
        // 通知権限をリクエスト（初回のみ）
        Task {
            await notificationService.requestNotificationPermission()
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenChecklistFromNotification"), object: nil, queue: .main) { note in
            // ここではアプリ全体の状態更新のみ。実際の画面遷移はContentView側でハンドル
        }
    }
    
    private func determineAppLocale() -> Locale {
        // Get the preferred language from Bundle
        let preferredLanguage = Bundle.main.preferredLocalizations.first ?? "en"
        
        // Map the language to appropriate locale identifier
        let localeIdentifier: String
        switch preferredLanguage {
        case "ja":
            localeIdentifier = "ja_JP"
        case "en":
            localeIdentifier = "en_US"
        default:
            // Fallback to system locale if neither ja nor en
            return Locale.current
        }
        
        return Locale(identifier: localeIdentifier)
    }
}
