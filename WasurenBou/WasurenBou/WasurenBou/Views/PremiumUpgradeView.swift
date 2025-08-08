//
//  PremiumUpgradeView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct PremiumUpgradeView: View {
    @ObservedObject var viewModel: ChecklistViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @ObservedObject private var store = StoreKitService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダー
                    headerView
                    
                    // 機能比較
                    featuresComparisonView
                    
                    // 購入/復元
                    purchaseButtonView
                    restoreButtonView
                    
                    if let error = store.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("プレミアム版")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                await store.loadProducts()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            // アイコン
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // タイトル
            Text("プレミアム版で\n広告を非表示に")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // サブタイトル（広告非表示のみ）
            Text("買い切りでアプリ内の広告をすべて非表示")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Features Comparison
    private var featuresComparisonView: some View {
        VStack(spacing: 16) {
            Text("機能比較")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PremiumFeatureRow(
                    title: "広告表示",
                    freeVersion: true,
                    premiumVersion: false,
                    isReverse: true
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Purchase Button
    private var purchaseButtonView: some View {
        VStack(spacing: 16) {
            // 価格表示
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(store.priceText.isEmpty ? "¥480" : store.priceText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("買い切り").font(.caption).fontWeight(.medium)
                        Text("月額料金なし").font(.caption2).foregroundColor(.secondary)
                    }
                }
                Text("一度の購入で永続利用。家族共有可")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: purchasePremium) {
                HStack {
                    if isPurchasing || store.isLoading { ProgressView().tint(.white).scaleEffect(0.8) }
                    Text(isPurchasing ? "処理中..." : "プレミアム版を購入")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isPurchasing || store.isLoading)
            
            Text("復元にはApp Storeへのサインインが必要です。サンドボックスは実機でお試しください。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var restoreButtonView: some View {
        Button(action: restorePurchases) {
            HStack {
                if isRestoring || store.isLoading { ProgressView().scaleEffect(0.8) }
                Text("購入を復元")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
        .disabled(isRestoring || store.isLoading)
    }
    
    // MARK: - Actions
    private func purchasePremium() {
        isPurchasing = true
        HapticFeedback.impact(.medium)
        Task {
            let success = await store.purchasePremium()
            isPurchasing = false
            if success {
                viewModel.isPremium = true
                HapticFeedback.notification(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
            }
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        Task {
            await store.restorePurchases()
            isRestoring = false
            viewModel.isPremium = StoreKitService.shared.isPremiumPurchased
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let title: String
    let freeVersion: Any
    let premiumVersion: Any
    let isReverse: Bool
    
    init(title: String, freeVersion: Any, premiumVersion: Any, isReverse: Bool = false) {
        self.title = title
        self.freeVersion = freeVersion
        self.premiumVersion = premiumVersion
        self.isReverse = isReverse
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 機能名
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 無料版
            featureStatus(freeVersion, isReverse: isReverse)
                .frame(width: 60)
            
            // プレミアム版
            featureStatus(premiumVersion, isReverse: false)
                .frame(width: 80)
        }
    }
    
    @ViewBuilder
    private func featureStatus(_ value: Any, isReverse: Bool) -> some View {
        if let stringValue = value as? String {
            Text(stringValue)
                .font(.caption)
                .foregroundColor(.secondary)
        } else if let boolValue = value as? Bool {
            Image(systemName: boolValue ? "checkmark" : "xmark")
                .foregroundColor(
                    isReverse ? (boolValue ? .red : .green) : (boolValue ? .green : .red)
                )
                .font(.caption)
        }
    }
}

#Preview {
    PremiumUpgradeView(viewModel: ChecklistViewModel())
}