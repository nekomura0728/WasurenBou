//
//  StoreKitService.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // プレミアムプロダクトID
    private let premiumProductID = "com.lizaria.wasurenbou.premium"
    private var updatesTask: Task<Void, Never>? = nil
    
    init() {
        // 起動時の購入状態の復元
        updatesTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [premiumProductID])
            await refreshPurchasedProducts()
        } catch {
            let nsError = error as NSError
            if nsError.domain == "ASDErrorDomain" && nsError.code == 509 {
                errorMessage = "App Storeにサインインしていません。実機でサインインするか、設定>開発用のプレミアム強制ONでテストしてください。"
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Purchase Handling
    func purchasePremium() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            if products.isEmpty {
                try? await Task.sleep(nanoseconds: 200_000_000)
                await loadProducts()
            }
            guard let product = products.first(where: { $0.id == premiumProductID }) else {
                errorMessage = StoreError.productNotFound.errorDescription
                return false
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshPurchasedProducts()
                    UserDefaults.standard.set(true, forKey: "isPremium")
                    return true
                } else {
                    errorMessage = StoreError.failedVerification.errorDescription
                    return false
                }
            case .pending:
                errorMessage = "購入が保留中です"
                return false
            case .userCancelled:
                return false
            default:
                return false
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == SKErrorDomain {
                if nsError.code == SKError.Code.paymentNotAllowed.rawValue {
                    errorMessage = "このデバイスでは購入が許可されていません"
                } else {
                    errorMessage = error.localizedDescription
                }
            } else if nsError.domain == NSURLErrorDomain {
                errorMessage = "ネットワークに接続できませんでした"
            } else {
                errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    // MARK: - Purchase Restoration
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            let nsError = error as NSError
            if nsError.domain == "ASDErrorDomain" && nsError.code == 509 {
                // シミュレータや未ログイン時の典型ケース
                errorMessage = "App Storeにサインインしていません。実機でサインインするか、設定>開発用のプレミアム強制ONでテストしてください。"
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Transaction Updates Listener
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try result.payloadValue
                if transaction.productID == premiumProductID {
                    await transaction.finish()
                    await refreshPurchasedProducts()
                }
            } catch {
                // ignore individual failures
            }
        }
    }
    
    // MARK: - Purchased State
    private func refreshPurchasedProducts() async {
        purchasedProductIDs.removeAll()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }
    
    // MARK: - Helper
    var isPremiumPurchased: Bool {
        return purchasedProductIDs.contains(premiumProductID) ||
               UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    var priceText: String {
        products.first(where: { $0.id == premiumProductID })?.displayPrice ?? ""
    }
}

// MARK: - Store Errors
enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return NSLocalizedString("purchase_verification_failed", comment: "Purchase verification failed")
        case .productNotFound:
            return NSLocalizedString("product_not_found", comment: "Product not found")
        }
    }
}

// MARK: - Preview Helper
extension StoreKitService {
    static var preview: StoreKitService {
        let service = StoreKitService()
        return service
    }
}