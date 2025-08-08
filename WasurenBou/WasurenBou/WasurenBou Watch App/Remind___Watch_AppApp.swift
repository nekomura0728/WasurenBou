//
//  Remind___Watch_AppApp.swift
//  Remind!!! Watch App
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

@main
struct Remind___Watch_App: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    setupWatch()
                }
        }
    }
    
    private func setupWatch() {
        // Watch固有の初期化
        print("🎯 Remind!!! Watch App initialized")
    }
}