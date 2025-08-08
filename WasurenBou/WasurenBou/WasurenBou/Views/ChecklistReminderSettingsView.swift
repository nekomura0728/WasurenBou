//
//  ChecklistReminderSettingsView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct ChecklistReminderSettingsView: View {
    let checklist: Checklist
    @ObservedObject var viewModel: ChecklistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var isRepeating = false
    @State private var repeatDays: Set<Int> = []
    
    private let weekdays = [
        (1, "日曜日"),
        (2, "月曜日"),
        (3, "火曜日"),
        (4, "水曜日"),
        (5, "木曜日"),
        (6, "金曜日"),
        (7, "土曜日")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("リマインダーを有効にする", isOn: $reminderEnabled)
                        .tint(.blue)
                } footer: {
                    Text("チェックリストの確認リマインダーを設定できます")
                }
                
                if reminderEnabled {
                    Section("時刻設定") {
                        DatePicker(
                            "通知時刻",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                    
                    Section {
                        Toggle("繰り返し設定", isOn: $isRepeating)
                            .tint(.blue)
                    } footer: {
                        Text("毎日または指定した曜日に繰り返し通知されます")
                    }
                    
                    if isRepeating {
                        Section("繰り返し曜日") {
                            ForEach(weekdays, id: \.0) { dayNumber, dayName in
                                Button(action: {
                                    if repeatDays.contains(dayNumber) {
                                        repeatDays.remove(dayNumber)
                                    } else {
                                        repeatDays.insert(dayNumber)
                                    }
                                }) {
                                    HStack {
                                        Text(dayName)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if repeatDays.contains(dayNumber) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section {
                        Text("プレビュー: \"\(checklist.title ?? "チェックリスト")の確認をお忘れなく！\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("通知内容")
                    }
                }
            }
            .navigationTitle("リマインダー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveReminderSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!reminderEnabled)
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        // チェックリストの現在のリマインダー設定を読み込み
        reminderEnabled = checklist.reminderEnabled
        reminderTime = checklist.reminderTime
        isRepeating = checklist.reminderIsRepeating
        repeatDays = checklist.reminderDays
        
        print("📖 リマインダー設定読み込み: \(checklist.title ?? "無題")")
        print("   有効: \(reminderEnabled)")
        print("   時刻: \(reminderTime)")
        print("   繰り返し: \(isRepeating)")
        print("   曜日: \(repeatDays)")
    }
    
    private func saveReminderSettings() {
        // ハプティックフィードバック
        HapticFeedback.notification(.success)
        
        // ViewModelを通じてリマインダー設定を保存
        viewModel.saveReminderSettings(
            for: checklist,
            enabled: reminderEnabled,
            time: reminderTime,
            isRepeating: isRepeating,
            repeatDays: repeatDays
        )
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let message: String
        if reminderEnabled {
            if isRepeating && !repeatDays.isEmpty {
                let dayNames = repeatDays.sorted().compactMap { dayNum in
                    weekdays.first { $0.0 == dayNum }?.1
                }
                message = "リマインダーを設定しました。\n毎週\(dayNames.joined(separator: "、"))の\(formatter.string(from: reminderTime))に通知されます。"
            } else if isRepeating {
                message = "リマインダーを設定しました。\n毎日\(formatter.string(from: reminderTime))に通知されます。"
            } else {
                message = "リマインダーを設定しました。\n\(formatter.string(from: reminderTime))に通知されます。"
            }
        } else {
            message = "リマインダーを無効にしました。"
        }
        
        print("💾 \(message)")
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: "外出用チェックリスト", emoji: "🚶‍♂️")
    
    return ChecklistReminderSettingsView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}