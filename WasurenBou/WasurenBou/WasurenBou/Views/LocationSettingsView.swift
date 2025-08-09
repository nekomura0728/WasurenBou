//
//  LocationSettingsView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationSettingsView: View {
    let checklist: Checklist
    @ObservedObject var viewModel: ChecklistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var locationName = ""
    @State private var radius: Double = 100.0
    @State private var isLocationEnabled = false
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var showingPremiumSheet = false
    @ObservedObject private var locationService = LocationService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerView
                    
                    // GPS設定（常時表示）
                    gpsSettingsView
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("gps_settings_title", comment: "GPS settings title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                
                // 保存ボタン（常時表示）
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("save", comment: "Save")) {
                        saveLocationSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
            // 起動時に既知の現在地があれば反映
            if latitude == nil || longitude == nil, let loc = locationService.lastKnownLocation {
                latitude = loc.coordinate.latitude
                longitude = loc.coordinate.longitude
            }
        }
        // LocationServiceの現在地更新を購読し、座標を反映
        .onReceive(locationService.$lastKnownLocation.compactMap { $0 }) { loc in
            latitude = loc.coordinate.latitude
            longitude = loc.coordinate.longitude
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(NSLocalizedString("location_based_reminder_title", comment: "Location based reminder title"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(NSLocalizedString("location_based_reminder_desc", comment: "Location based reminder description"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("location_name_hint_desc", comment: "Location name hint description"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let err = locationService.errorMessage, !err.isEmpty {
                VStack(spacing: 8) {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button(NSLocalizedString("open_settings", comment: "Open settings")) {
                        LocationService.shared.openAppSettings()
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    // MARK: - GPS Settings
    private var gpsSettingsView: some View {
        VStack(spacing: 20) {
            // GPS有効/無効切り替え
            Toggle(NSLocalizedString("location_toggle_enable", comment: "Enable location toggle"), isOn: $isLocationEnabled)
                .toggleStyle(SwitchToggleStyle())
            
            if isLocationEnabled {
                VStack(spacing: 16) {
                    // ミニマップ（座標があるときに表示）
                    if let lat = latitude, let lon = longitude {
                        MiniMapView(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), radius: radius)
                            .frame(height: 180)
                            .cornerRadius(12)
                            .accessibilityLabel(NSLocalizedString("map_preview_a11y", comment: "Map preview a11y"))
                    }
                    // 場所名設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("location_name", comment: "Location name label"))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField(NSLocalizedString("location_name_placeholder", comment: "Location name placeholder"), text: $locationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityHint(NSLocalizedString("location_name_a11y_hint", comment: "Location name a11y hint"))
                    }
                    
                    // 範囲設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: NSLocalizedString("detection_range_m", comment: "Detection range"), Int(radius)))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Slider(value: $radius, in: 50...500, step: 25)
                            .accentColor(.blue)
                            .accessibilityLabel(NSLocalizedString("detection_range_label", comment: "Detection range label"))
                            .accessibilityValue(String(format: NSLocalizedString("meters_value", comment: "Meters value"), Int(radius)))
                        
                        HStack {
                            Text("50m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("500m")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 現在地設定ボタン
                    Button(action: setCurrentLocation) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(NSLocalizedString("use_current_location", comment: "Use current location"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    .accessibilityHint(NSLocalizedString("use_current_location_hint", comment: "Use current location hint"))
                    
                    if let lat = latitude, let lon = longitude {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.secondary)
                            Text(String(format: "%.5f, %.5f", lat, lon))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .animation(.easeInOut, value: isLocationEnabled)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Premium Prompt
    private var premiumPromptView: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("プレミアム機能")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("GPS連動機能はプレミアム版限定です。\n¥480の買い切りでご利用いただけます。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("プレミアム版を購入") {
                showingPremiumSheet = true
            }
            .fontWeight(.semibold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .sheet(isPresented: $showingPremiumSheet) {
            PremiumUpgradeView(viewModel: viewModel)
        }
    }
    
    // MARK: - Actions
    private func loadCurrentSettings() {
        isLocationEnabled = checklist.isLocationBased
        locationName = checklist.locationName ?? ""
        radius = checklist.radius
        latitude = checklist.latitude
        longitude = checklist.longitude
    }
    
    private func saveLocationSettings() {
        if isLocationEnabled {
            guard let lat = latitude, let lon = longitude else {
                LocationService.shared.errorMessage = "現在地が取得できていません。『現在地の座標を使用』を押してから保存してください。"
                return
            }
            viewModel.enableLocationReminder(
                for: checklist,
                locationName: locationName.isEmpty ? "（未命名の場所）" : locationName,
                latitude: lat,
                longitude: lon,
                radius: radius
            )
        } else {
            viewModel.disableLocationReminder(for: checklist)
        }
        
        HapticFeedback.notification(.success)
        dismiss()
    }
    
    private func setCurrentLocation() {
        LocationService.shared.requestAuthorization(always: true)
        LocationService.shared.requestSingleLocation()
        HapticFeedback.impact(.medium)
    }
}

// MARK: - MiniMap View (Simple Overlay)
struct MiniMapView: View {
    var center: CLLocationCoordinate2D
    var radius: Double
    @State private var region: MKCoordinateRegion = .init()
    
    var body: some View {
        Map(
            coordinateRegion: Binding(
                get: { regionForCenter(center) },
                set: { region = $0 }
            ),
            interactionModes: []
        )
        .overlay(
            Circle()
                .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                .background(Circle().fill(Color.blue.opacity(0.1)))
                .padding(40)
        )
        .onAppear {
            region = regionForCenter(center)
        }
    }
    
    private func regionForCenter(_ center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let meters = max(200, radius * 4)
        let span = MKCoordinateSpan(latitudeDelta: meters / 111_000, longitudeDelta: meters / 111_000)
        return MKCoordinateRegion(center: center, span: span)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: "外出用", emoji: "🚶‍♂️")
    
    return LocationSettingsView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}