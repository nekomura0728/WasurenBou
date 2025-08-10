import Foundation
import CoreLocation
import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastKnownLocation: CLLocation?
    @Published var errorMessage: String?
    
    private let manager = CLLocationManager()
    
    // checklistID -> regionIdentifier
    private var monitoredRegionsByChecklist: [String: String] = [:]
    private var pendingSingleLocationRequest = false
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Authorization
    func requestAuthorization(always: Bool = true) {
        if always {
            manager.requestAlwaysAuthorization()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    // 一度きりの現在地要求
    func requestSingleLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .notDetermined:
            pendingSingleLocationRequest = true
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "位置情報がオフになっています。設定＞プライバシー＞位置情報サービスから許可してください。"
        @unknown default:
            break
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - Monitoring
    func startMonitoring(checklistID: String, title: String, latitude: Double, longitude: Double, radius: Double) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        if authorizationStatus == .notDetermined { requestAuthorization(always: true) }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let clampedRadius = max(50, min(radius, 500))
        let identifier = "checklist_region_\(checklistID)"
        
        // Stop existing for this checklist
        if let existingId = monitoredRegionsByChecklist[checklistID] {
            stopMonitoring(regionIdentifier: existingId)
        }
        
        let region = CLCircularRegion(center: coordinate, radius: clampedRadius, identifier: identifier)
        region.notifyOnExit = true
        region.notifyOnEntry = false
        manager.startMonitoring(for: region)
        monitoredRegionsByChecklist[checklistID] = identifier
        
    }
    
    func stopMonitoringForChecklist(checklistID: String) {
        if let identifier = monitoredRegionsByChecklist[checklistID] {
            stopMonitoring(regionIdentifier: identifier)
            monitoredRegionsByChecklist.removeValue(forKey: checklistID)
        }
    }
    
    private func stopMonitoring(regionIdentifier: String) {
        for region in manager.monitoredRegions {
            if region.identifier == regionIdentifier, let circular = region as? CLCircularRegion {
                manager.stopMonitoring(for: circular)
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                if self.pendingSingleLocationRequest {
                    self.pendingSingleLocationRequest = false
                    self.manager.requestLocation()
                }
            case .denied, .restricted:
                self.errorMessage = "位置情報の権限が拒否されています。設定アプリから変更してください。"
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastKnownLocation = location
            self.errorMessage = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as NSError
        Task { @MainActor in
            if clError.domain == kCLErrorDomain {
                switch CLError.Code(rawValue: clError.code) {
                case .denied:
                    self.errorMessage = "位置情報の権限が拒否されています。設定アプリで許可してください。"
                case .locationUnknown:
                    self.errorMessage = "現在地を取得できませんでした。屋内や電波状況をご確認のうえ、もう一度お試しください。"
                default:
                    self.errorMessage = error.localizedDescription
                }
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // リージョン退出時にチェックリストを開く通知を投げる
        Task { @MainActor in
            guard region.identifier.hasPrefix("checklist_region_") else { return }
            let checklistID = String(region.identifier.dropFirst("checklist_region_".count))
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenChecklistFromNotification"),
                object: nil,
                userInfo: ["checklistID": checklistID, "checklistTitle": "チェックリスト"]
            )
            
            // バックグラウンド時のためにローカル通知も補助的に発行
            let content = UNMutableNotificationContent()
            content.title = "📍 場所から離れました"
            content.body = "チェックリストを確認しましょう"
            content.categoryIdentifier = "CHECKLIST_REMINDER"
            content.userInfo = ["type": "checklist_reminder", "checklistID": checklistID]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "geo_exit_\(checklistID)_\(UUID().uuidString)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    }
} 