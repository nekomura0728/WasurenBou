// WatchConnectivityService - リリース版では無効化
// 将来のApple Watch対応時に使用予定

import Foundation

// リリース版用のダミークラス
class WatchConnectivityService: ObservableObject {
    static let shared = WatchConnectivityService()
    
    // 何もしないメソッド群
    func syncReminderToWatch(_ reminder: Any) { }
    func syncReminderCompletionToWatch(_ reminder: Any) { }
    func syncTemplatesToWatch() { }
    
    private init() { }
}