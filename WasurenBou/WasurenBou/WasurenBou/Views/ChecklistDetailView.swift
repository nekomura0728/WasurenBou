//
//  ChecklistDetailView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct ChecklistDetailView: View {
    @ObservedObject var checklist: Checklist
    @ObservedObject var viewModel: ChecklistViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddItem = false
    @State private var newItemTitle = ""
    @State private var showingLocationSettings = false
    @State private var showingReminderSettings = false
    @State private var showingPremiumUpgrade = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ヘッダー情報
                headerView
                
                // 日次リセットの説明
                HStack(spacing: 8) {
                    Image(systemName: "calendar"
                    )
                        .foregroundColor(.secondary)
                    Text("日付が変わるとチェックは自動的にリセットされます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        viewModel.resetChecklistItems(checklist)
                    } label: {
                        Label("手動でリセット", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // チェックリストアイテム
                if checklist.itemsArray.isEmpty {
                    emptyItemsView
                } else {
                    itemsListView
                }
                
                // 広告エリア（無料版のみ）
                if !viewModel.isPremium {
                    adBannerView
                }
            }
            .navigationTitle(checklist.title ?? "チェックリスト")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddItem = true }) {
                            Label("アイテム追加", systemImage: "plus")
                        }
                        
                        Button(action: { showingReminderSettings = true }) {
                            Label("リマインダー設定", systemImage: "alarm")
                        }
                        
                        if viewModel.isPremium {
                            Button(action: { showingLocationSettings = true }) {
                                Label("GPS設定", systemImage: "location")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: deleteChecklist) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddChecklistItemView(
                checklist: checklist,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showingLocationSettings) {
            LocationSettingsView(
                checklist: checklist,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showingReminderSettings) {
            ChecklistReminderSettingsView(
                checklist: checklist,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView(viewModel: viewModel)
        }
        .onAppear {
            Task { @MainActor in
                viewModel.autoResetIfNeeded(for: checklist)
                await viewModel.loadChecklists()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // 絵文字とタイトル
            HStack(spacing: 12) {
                Text(checklist.emoji ?? "📋")
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(checklist.title ?? "チェックリスト")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text("\(checklist.itemsArray.count)個のアイテム")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if checklist.isLocationBased {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                Text(checklist.locationName ?? "GPS連動")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        }
                        
                        if checklist.reminderEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "alarm.fill")
                                Text(checklist.getReminderDescription())
                            }
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
            }
            
            // 進行状況バー
            ProgressView(value: checklist.completionPercentage) {
                HStack {
                    Text("進行状況")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(checklist.completionPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(checklist.isCompleted ? .green : .blue)
                }
            }
            .progressViewStyle(LinearProgressViewStyle())
            
            // 完了メッセージ
            if checklist.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("すべて完了しました！🎉")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // リマインダー設定ボタン
            HStack {
                Button(action: { showingReminderSettings = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("リマインダー設定")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(checklist.reminderEnabled ? checklist.getReminderDescription() : "リマインダーなし")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.05))
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 8)
        .background(Color.systemCardBackground)
    }
    
    // MARK: - Empty Items View
    private var emptyItemsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "list.bullet")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("アイテムがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddItem = true }) {
                Text("最初のアイテムを追加")
                    .fontWeight(.medium)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Items List
    private var itemsListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(checklist.itemsArray, id: \.objectID) { item in
                    ChecklistItemRow(
                        item: item,
                        onToggle: { viewModel.toggleItem(item) },
                        onDelete: { viewModel.deleteItem(item) }
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadChecklists()
        }
    }
    
    // MARK: - Ad Banner
    private var adBannerView: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: {
                // プレミアム版へのアップグレードを促す
                showingPremiumUpgrade = true
            }) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.orange)
                    
                    Text("プレミアム版で広告なし →")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Actions
    private func deleteChecklist() {
        viewModel.deleteChecklist(checklist)
        dismiss()
    }
}

// MARK: - Checklist Item Row
struct ChecklistItemRow: View {
    let item: ChecklistItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // チェックボックス
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isChecked ? .green : .gray)
                    .scaleEffect(item.isChecked ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: item.isChecked)
            }
            .buttonStyle(PlainButtonStyle())
            
            // アイテム名
            Text(item.title ?? "アイテム")
                .font(.body)
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .strikethrough(item.isChecked)
                .animation(.easeInOut(duration: 0.2), value: item.isChecked)
            
            Spacer()
            
            // 削除ボタン
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.systemCardBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: "外出用チェックリスト", emoji: "🚶‍♂️")
    
    return ChecklistDetailView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}