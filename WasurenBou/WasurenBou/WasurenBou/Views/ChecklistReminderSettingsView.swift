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
    
    private var weekdays: [(Int, String)] {
        [
            (1, NSLocalizedString("sunday", comment: "")),
            (2, NSLocalizedString("monday", comment: "")),
            (3, NSLocalizedString("tuesday", comment: "")),
            (4, NSLocalizedString("wednesday", comment: "")),
            (5, NSLocalizedString("thursday", comment: "")),
            (6, NSLocalizedString("friday", comment: "")),
            (7, NSLocalizedString("saturday", comment: ""))
        ]
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(String(localized: "enable_reminder"), isOn: $reminderEnabled)
                        .tint(.blue)
                } footer: {
                    Text(LocalizedStringKey("checklist_reminder_footer"))
                }
                
                if reminderEnabled {
                    Section(String(localized: "time_settings_section")) {
                        DatePicker(
                            String(localized: "notification_time"),
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                    
                    Section {
                        Toggle(String(localized: "repeat_settings"), isOn: $isRepeating)
                            .tint(.blue)
                    } footer: {
                        Text(LocalizedStringKey("repeat_footer"))
                    }
                    
                    if isRepeating {
                        Section(String(localized: "repeat_days_section")) {
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
                        Text(String(format: NSLocalizedString("notification_preview", comment: ""), checklist.title ?? NSLocalizedString("checklist", comment: "")))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } header: {
                        Text(LocalizedStringKey("notification_content_header"))
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("reminder_settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "save")) {
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
        
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: NSLocalizedString("going_out_checklist", comment: ""), emoji: "🚶‍♂️")
    
    return ChecklistReminderSettingsView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}