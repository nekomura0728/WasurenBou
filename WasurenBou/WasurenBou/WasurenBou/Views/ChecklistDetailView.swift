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
                    Text(LocalizedStringKey("daily_reset_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        viewModel.resetChecklistItems(checklist)
                    } label: {
                        Label(LocalizedStringKey("manual_reset"), systemImage: "arrow.counterclockwise")
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
            .navigationTitle(checklist.title ?? NSLocalizedString("checklist", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("done_button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddItem = true }) {
                            Label(LocalizedStringKey("add_item"), systemImage: "plus")
                        }
                        
                        Button(action: { showingReminderSettings = true }) {
                            Label(LocalizedStringKey("reminder_settings"), systemImage: "alarm")
                        }
                        
                        // GPS設定は常に表示
                        Button(action: { showingLocationSettings = true }) {
                            Label(LocalizedStringKey("gps_settings_title"), systemImage: "location")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: deleteChecklist) {
                            Label(LocalizedStringKey("delete"), systemImage: "trash")
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
                    Text(checklist.title ?? NSLocalizedString("checklist", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 8) {
                        Text(String(format: NSLocalizedString("items_count_format", comment: ""), checklist.itemsArray.count))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if checklist.isLocationBased {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                Text(checklist.locationName ?? NSLocalizedString("gps_location", comment: ""))
                            }
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                            .accessibilityLabel(String(format: NSLocalizedString("location_toggle_enable", comment: ""), checklist.locationName ?? NSLocalizedString("gps_location", comment: "")))
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
                            .accessibilityLabel(String(format: NSLocalizedString("reminder_settings", comment: "") + ": %@", checklist.getReminderDescription()))
                        }
                    }
                }
                
                Spacer()
            }
            
            // 進捗リング + 次リセットまで
            HStack(spacing: 16) {
                progressRing
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("progress"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: NSLocalizedString("completion_percentage", comment: ""), Int(checklist.completionPercentage * 100)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(checklist.isCompleted ? .green : .primary)
                    Text(String(format: NSLocalizedString("auto_reset_in", comment: ""), hoursUntilMidnightText()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityLabel(String(format: NSLocalizedString("auto_reset_in", comment: ""), hoursUntilMidnightText()))
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(format: NSLocalizedString("progress", comment: "") + " %d%%. " + NSLocalizedString("auto_reset_in", comment: ""), Int(checklist.completionPercentage * 100), hoursUntilMidnightText()))
            
            // 完了メッセージ
            if checklist.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(LocalizedStringKey("all_completed_message"))
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
                            Text(LocalizedStringKey("reminder_settings"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(checklist.reminderEnabled ? checklist.getReminderDescription() : NSLocalizedString("no_reminder", comment: ""))
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
                .accessibilityHint(NSLocalizedString("tap_to_set_reminder", comment: ""))
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, 8)
        .background(Color.systemCardBackground)
    }
    
    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(max(0.01, min(1.0, checklist.completionPercentage))))
                .stroke(checklist.isCompleted ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(checklist.completionPercentage * 100))%")
                    .font(.headline)
                    .monospacedDigit()
                Text("完了")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
    }
    
    private func hoursUntilMidnightText() -> String {
        let calendar = Calendar.current
        let now = Date()
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        let remaining = startOfTomorrow.timeIntervalSince(now)
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 && minutes > 0 {
            return String(format: NSLocalizedString("hours_minutes_format", comment: ""), hours, minutes)
        } else if hours > 0 {
            return String(format: NSLocalizedString("hours_only_format", comment: ""), hours)
        } else {
            return String(format: NSLocalizedString("minutes_only_format", comment: ""), minutes)
        }
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
            .accessibilityLabel(item.isChecked ? "未完了にする: \(item.title ?? "アイテム")" : "完了にする: \(item.title ?? "アイテム")")
            .accessibilityHint("ダブルタップで切り替え")
            
            // アイテム名
            Text(item.title ?? "アイテム")
                .font(.body)
                .foregroundColor(item.isChecked ? .secondary : .primary)
                .strikethrough(item.isChecked)
                .animation(.easeInOut(duration: 0.2), value: item.isChecked)
                .accessibilityLabel("アイテム: \(item.title ?? "")")
            
            Spacer()
            
            // 削除ボタン
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("削除: \(item.title ?? "アイテム")")
        }
        .padding()
        .background(Color.systemCardBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: NSLocalizedString("going_out_checklist", comment: ""), emoji: "🚶‍♂️")
    
    return ChecklistDetailView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}