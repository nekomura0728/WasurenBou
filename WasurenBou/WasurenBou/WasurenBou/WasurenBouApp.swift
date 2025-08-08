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
                .withErrorHandling()
                .onAppear {
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
}
