import Foundation
import AppTrackingTransparency
import AdSupport
import SwiftUI

@MainActor
final class ConsentService: ObservableObject {
    static let shared = ConsentService()
    
    @AppStorage("attRequested") private var attRequested: Bool = false
    
    private init() {}
    
    func requestATTIfNeeded() async {
        guard #available(iOS 14, *) else { return }
        guard !attRequested else { return }
        let status = ATTrackingManager.trackingAuthorizationStatus
        if status == .notDetermined {
            await withCheckedContinuation { cont in
                ATTrackingManager.requestTrackingAuthorization { _ in
                    cont.resume()
                }
            }
            attRequested = true
        }
    }
    
    func requestGDPRIfNeeded() async {
        // 簡易ダミー。実際はUMP SDKなどを導入して同意フォームを表示
        // EU圏判定や保持は省略し、ここでは即時許可とする
        await Task.yield()
    }
} 