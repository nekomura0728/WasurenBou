//
//  ErrorHandlingService.swift
//  WasurenBou
//
//  Created by Claude on 2025/08/07.
//

import Foundation
import SwiftUI

// MARK: - Error Types
enum AppError: LocalizedError {
    case networkError(String)
    case dataError(String)
    case permissionDenied(String)
    case notificationError(String)
    case speechRecognitionError(String)
    case coreDataError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .dataError(let message):
            return "データエラー: \(message)"
        case .permissionDenied(let message):
            return "権限エラー: \(message)"
        case .notificationError(let message):
            return "通知エラー: \(message)"
        case .speechRecognitionError(let message):
            return "音声認識エラー: \(message)"
        case .coreDataError(let message):
            return "データベースエラー: \(message)"
        case .unknown(let message):
            return "エラー: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "インターネット接続を確認してください"
        case .dataError:
            return "アプリを再起動してください"
        case .permissionDenied:
            return "設定から必要な権限を許可してください"
        case .notificationError:
            return "通知設定を確認してください"
        case .speechRecognitionError:
            return "マイクの権限を確認するか、手動で入力してください"
        case .coreDataError:
            return "データの同期に問題があります。しばらくお待ちください"
        case .unknown:
            return "問題が続く場合はアプリを再起動してください"
        }
    }
    
    var userFriendlyMessage: String {
        let baseMessage = errorDescription ?? "エラーが発生しました"
        if let suggestion = recoverySuggestion {
            return "\(baseMessage)\n\(suggestion)"
        }
        return baseMessage
    }
}

// MARK: - Error Handling Service
@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var showError: Bool = false
    @Published var errorHistory: [ErrorRecord] = []
    
    private let maxErrorHistory = 50
    private var retryHandlers: [String: () async -> Void] = [:]
    
    private init() {}
    
    // MARK: - Error Recording
    struct ErrorRecord {
        let id = UUID()
        let error: AppError
        let timestamp: Date
        let context: String?
    }
    
    // MARK: - Error Handling Methods
    func handle(_ error: Error, context: String? = nil, retryHandler: (() async -> Void)? = nil) {
        let appError = categorizeError(error)
        
        // Record error
        let record = ErrorRecord(error: appError, timestamp: Date(), context: context)
        errorHistory.append(record)
        
        // Maintain history limit
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }
        
        // Store retry handler if provided
        if let handler = retryHandler {
            retryHandlers[record.id.uuidString] = handler
        }
        
        // Update UI
        currentError = appError
        showError = true
        
        // Log error for debugging
        #if DEBUG
        #endif
    }
    
    // MARK: - Error Categorization
    private func categorizeError(_ error: Error) -> AppError {
        // Check for specific error types
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        
        // Categorize based on error domain and code
        switch nsError.domain {
        case NSURLErrorDomain:
            return .networkError(nsError.localizedDescription)
        case "NSCocoaErrorDomain":
            if nsError.code >= 4864 && nsError.code <= 4991 {
                return .coreDataError(nsError.localizedDescription)
            }
            return .dataError(nsError.localizedDescription)
        default:
            // Check error description for hints
            let description = error.localizedDescription.lowercased()
            if description.contains("permission") || description.contains("denied") {
                return .permissionDenied(error.localizedDescription)
            } else if description.contains("notification") {
                return .notificationError(error.localizedDescription)
            } else if description.contains("speech") || description.contains("recognition") {
                return .speechRecognitionError(error.localizedDescription)
            }
            return .unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Retry Logic
    func retry(for errorId: String) async {
        guard let handler = retryHandlers[errorId] else { return }
        
        // Clear current error
        currentError = nil
        showError = false
        
        // Execute retry
        await handler()
        
        // Clean up handler
        retryHandlers.removeValue(forKey: errorId)
    }
    
    // MARK: - Error Dismissal
    func dismissError() {
        withAnimation(.easeOut(duration: 0.2)) {
            currentError = nil
            showError = false
        }
    }
    
    // MARK: - Error Analytics
    func getMostCommonErrors(limit: Int = 5) -> [(AppError, Int)] {
        let errorGroups = Dictionary(grouping: errorHistory) { record in
            record.error.errorDescription ?? "Unknown"
        }
        
        return errorGroups
            .compactMap { key, records in
                records.first.map { ($0.error, records.count) }
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0 }
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
        retryHandlers.removeAll()
    }
}

// MARK: - Error Alert View
struct ErrorAlertView: View {
    @ObservedObject var errorService = ErrorHandlingService.shared
    @State private var showRetryButton = false
    
    var body: some View {
        if errorService.showError, let error = errorService.currentError {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconForError(error))
                        .font(.title2)
                        .foregroundColor(colorForError(error))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.errorDescription ?? "エラーが発生しました")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        errorService.dismissError()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if showRetryButton {
                    Button(action: {
                        Task {
                            // Retry logic would go here
                            errorService.dismissError()
                        }
                    }) {
                        Label("再試行", systemImage: "arrow.clockwise")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color(.systemGray).opacity(0.3), radius: 8, x: 0, y: 4)
            .padding()
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: errorService.showError)
            .onAppear {
                // Auto-dismiss after 5 seconds for non-critical errors
                if !isCriticalError(error) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if errorService.currentError?.errorDescription == error.errorDescription {
                            errorService.dismissError()
                        }
                    }
                }
                
                // Show retry button for network errors
                showRetryButton = isRetryableError(error)
            }
        }
    }
    
    private func iconForError(_ error: AppError) -> String {
        switch error {
        case .networkError:
            return "wifi.exclamationmark"
        case .dataError, .coreDataError:
            return "externaldrive.badge.exclamationmark"
        case .permissionDenied:
            return "lock.shield"
        case .notificationError:
            return "bell.slash"
        case .speechRecognitionError:
            return "mic.slash"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
    
    private func colorForError(_ error: AppError) -> Color {
        switch error {
        case .permissionDenied, .notificationError, .speechRecognitionError:
            return .orange
        case .networkError, .dataError, .coreDataError:
            return .red
        case .unknown:
            return .yellow
        }
    }
    
    private func isCriticalError(_ error: AppError) -> Bool {
        switch error {
        case .coreDataError, .dataError:
            return true
        default:
            return false
        }
    }
    
    private func isRetryableError(_ error: AppError) -> Bool {
        switch error {
        case .networkError:
            return true
        default:
            return false
        }
    }
}

// MARK: - View Extension for Error Handling
extension View {
    func withErrorHandling() -> some View {
        self.overlay(
            ErrorAlertView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(ErrorHandlingService.shared.showError)
        )
    }
}