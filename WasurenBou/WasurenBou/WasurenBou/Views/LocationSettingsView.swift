//
//  LocationSettingsView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI
import CoreLocation

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
                    
                    // GPS設定
                    if viewModel.isPremium {
                        gpsSettingsView
                    } else {
                        premiumPromptView
                    }
                }
                .padding()
            }
            .navigationTitle("GPS設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                if viewModel.isPremium {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("保存") {
                            saveLocationSettings()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("場所ベースリマインダー")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("設定した場所から離れる時に\nチェックリストを自動表示します")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("場所名は任意のメモです（例：自宅、会社、スーパー）。\n現在地ボタンは座標のみを反映します。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let err = locationService.errorMessage, !err.isEmpty {
                VStack(spacing: 8) {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    Button("設定を開く") {
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
            Toggle("GPS連動を有効にする", isOn: $isLocationEnabled)
                .toggleStyle(SwitchToggleStyle())
            
            if isLocationEnabled {
                VStack(spacing: 16) {
                    // 場所名設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text("場所名")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("例：自宅（任意）", text: $locationName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // 範囲設定
                    VStack(alignment: .leading, spacing: 8) {
                        Text("検知範囲: \(Int(radius))m")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Slider(value: $radius, in: 50...500, step: 25)
                            .accentColor(.blue)
                        
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
                            Text("現在地の座標を使用")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
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

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: "外出用", emoji: "🚶‍♂️")
    
    return LocationSettingsView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}