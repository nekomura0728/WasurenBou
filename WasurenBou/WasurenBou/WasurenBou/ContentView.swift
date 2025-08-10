//
//  ContentView.swift
//  WasurenBou
//
//  Created by 前村　真之介 on 2025/08/06.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel = ReminderViewModel()
    @StateObject private var checklistViewModel = ChecklistViewModel()
    @State private var showingTimeSelector = false
    @State private var pendingReminderTitle = ""
    
    // 通知遷移
    @State private var checklistToOpen: Checklist? = nil
    
    // iPad対応のカラム幅計算
    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
    
    var body: some View {
        TabView {
            // リマインダータブ
            NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // ヘッダー
                        HStack {
                            VStack(spacing: 8) {
                                Text("Remind!!!")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                    .accessibilityAddTraits(.isHeader)
                                    .accessibilityLabel("Remind!!! app")
                            }
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 音声入力ボタン
                        VoiceInputButton { recognizedText in
                            pendingReminderTitle = recognizedText
                            showingTimeSelector = true
                        }
                    
                        // 今日のリマインダー一覧
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(NSLocalizedString("today_reminders", comment: ""))
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                if !viewModel.todayReminders.isEmpty {
                                    Text("\(viewModel.todayReminders.count)件")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if viewModel.todayReminders.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundColor(Color(red: 0.298, green: 0.733, blue: 0.400))
                                    
                                    Text(NSLocalizedString("no_reminders_today", comment: ""))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text(NSLocalizedString("create_reminder_prompt", comment: ""))
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.todayReminders) { reminder in
                                        ReminderCard(reminder: reminder) {
                                            viewModel.completeReminder(reminder)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // よく使うテンプレート
                        VStack(alignment: .leading, spacing: 16) {
                            Text(NSLocalizedString("frequently_used_templates", comment: ""))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.horizontal, 20)
                            
                            TemplateGridView(
                                viewModel: viewModel,
                                pendingReminderTitle: $pendingReminderTitle,
                                showingTimeSelector: $showingTimeSelector,
                                columns: columns
                            )
                            .padding(.horizontal, 20)
                        }
                    
                        // エラーメッセージ表示
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color("Danger"))
                                
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Button("×") {
                                    viewModel.clearError()
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 32)
                }
                
                // 広告エリア（無料版のみ）
                if !checklistViewModel.isPremium {
                    AdMobService.shared.loadBannerAd()
                        .frame(height: 50)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .accessibilityElement(children: .contain)
            .loadingOverlay(isLoading: viewModel.isLoading, message: NSLocalizedString("loading_data", comment: ""))
            .sheet(isPresented: $showingTimeSelector) {
                TimeSelectionView(
                    reminderTitle: pendingReminderTitle,
                    viewModel: viewModel,
                    isPresented: $showingTimeSelector
                )
            }
            .sheet(item: $checklistToOpen) { checklist in
                ChecklistDetailView(checklist: checklist, viewModel: checklistViewModel)
            }
            }
            .tabItem {
                Image(systemName: "alarm")
                Text(NSLocalizedString("tab_reminders", comment: ""))
            }
            
            // チェックリストタブ
            ChecklistView(viewModel: checklistViewModel)
                .tabItem {
                    Image(systemName: "checklist")
                    Text(NSLocalizedString("tab_checklists", comment: ""))
                }
            
            // 設定タブ
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gear")
                    Text(NSLocalizedString("tab_settings", comment: ""))
                }
        }
        .onAppear {
            checklistViewModel.loadChecklists()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenChecklistFromNotification"))) { notification in
            guard let checklistID = notification.userInfo?["checklistID"] as? String,
                  let uuid = UUID(uuidString: checklistID) else { return }
            
            let request: NSFetchRequest<Checklist> = Checklist.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            request.fetchLimit = 1
            if let result = try? viewContext.fetch(request).first {
                checklistToOpen = result
                checklistViewModel.selectChecklist(result)
            }
        }
    }
}

struct VoiceInputButton: View {
    let onRecognized: (String) -> Void
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                isPressed.toggle()
                // ハプティックフィードバック
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                Task {
                    if speechService.isRecording {
                        speechService.stopRecording()
                        let processedText = speechService.processTranscription()
                        if !processedText.isEmpty && processedText != "音声を認識できませんでした" {
                            onRecognized(processedText)
                        }
                    } else {
                        await speechService.startRecording()
                    }
                }
            }) {
                Image(systemName: speechService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(speechService.isRecording ? Color("Danger") : Color.accentColor)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 120, height: 120)
                            .shadow(color: speechService.isRecording ? 
                                   Color("Danger").opacity(0.3) : 
                                   Color.accentColor.opacity(0.2), 
                                   radius: speechService.isRecording ? 12 : 8, x: 0, y: 4)
                    )
            }
            .scaleEffect(speechService.isRecording ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: speechService.isRecording)
            .accessibilityLabel(speechService.isRecording ? NSLocalizedString("stop_recording", comment: "") : NSLocalizedString("start_voice_input", comment: ""))
            .accessibilityHint(NSLocalizedString("voice_input_hint", comment: ""))
            .accessibilityAddTraits(.isButton)
            
            VStack(spacing: 8) {
                Text(speechService.isRecording ? NSLocalizedString("voice_recognizing", comment: "") : "🗣️ \(NSLocalizedString("tap_to_speak", comment: ""))")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                
                if speechService.isRecording {
                    Text(NSLocalizedString("recognizing_speech", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                } else {
                    Text(NSLocalizedString("tap_to_speak_prompt", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
                
                if speechService.isRecording && !speechService.transcription.isEmpty {
                    Text(speechService.transcription)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(Color.accentColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color(.systemGray).opacity(0.2), radius: 2, x: 0, y: 1)
                        .accessibilityLabel("認識中のテキスト: \(speechService.transcription)")
                }
                
                if !speechService.isAuthorized && speechService.authorizationStatus == .denied {
                    Text(NSLocalizedString("speech_permission_warning", comment: ""))
                        .font(.caption)
                        .foregroundColor(Color("Danger"))
                        .multilineTextAlignment(.center)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color(.systemGray).opacity(0.2), radius: 2, x: 0, y: 1)
                        .accessibilityLabel("警告: 音声認識の権限が必要です")
                }
            }
        }
    }
}

struct ReminderListView: View {
    @ObservedObject var viewModel: ReminderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("today_reminders", comment: ""))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.todayReminders.isEmpty {
                Text(NSLocalizedString("no_reminders_today", comment: ""))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.todayReminders) { reminder in
                        ReminderCard(reminder: reminder) {
                            viewModel.completeReminder(reminder)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReminderCard: View {
    let reminder: Reminder
    let onComplete: () -> Void
    @State private var isPressed = false
    
    var urgencyColor: Color {
        let timeLeft = reminder.scheduledTime?.timeIntervalSinceNow ?? 0
        if timeLeft <= 0 { return Color("Danger") } // 赤
        if timeLeft <= 300 { return Color("Warning") } // オレンジ 5分以内
        return Color("Success") // 緑
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(urgencyColor)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.title ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .accessibilityLabel(reminder.title ?? "")
                
                Text(reminder.scheduledTime ?? Date(), style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .accessibilityLabel("時刻: \(reminder.scheduledTime?.formatted(date: .omitted, time: .shortened) ?? "")")
            }
            
            Spacer()
            
            Button(NSLocalizedString("complete", comment: "")) {
                isPressed = true
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onComplete()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color("Success"))
            .cornerRadius(12)
            .shadow(color: Color("Success").opacity(0.3), radius: 4, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .accessibilityLabel(NSLocalizedString("complete", comment: ""))
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reminder.title ?? ""), \(reminder.scheduledTime?.formatted(date: .omitted, time: .shortened) ?? "")")
        .accessibilityHint("Tap the complete button to finish this reminder")
    }
}

struct TemplateGridView: View {
    @ObservedObject var viewModel: ReminderViewModel
    @Binding var pendingReminderTitle: String
    @Binding var showingTimeSelector: Bool
    let columns: [GridItem]
    
    let defaultTemplates = [
        ("🧺", NSLocalizedString("template_laundry", comment: "")),
        ("💊", NSLocalizedString("template_medicine", comment: "")),
        ("🗑️", NSLocalizedString("template_trash", comment: "")),
        ("📞", NSLocalizedString("template_call_mom", comment: "")),
        ("🛒", NSLocalizedString("template_buy_milk", comment: "")),
        ("🚗", NSLocalizedString("template_check_car", comment: ""))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("frequently_used_templates", comment: ""))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: columns, spacing: 12) {
                // カスタムテンプレート
                ForEach(viewModel.templates.prefix(3)) { template in
                    TemplateButton(
                        emoji: template.emoji ?? "📝", 
                        title: template.title ?? NSLocalizedString("reminder", comment: "Default reminder title")
                    ) {
                        pendingReminderTitle = template.title ?? NSLocalizedString("reminder", comment: "Default reminder title")
                        showingTimeSelector = true
                    }
                }
                
                // デフォルトテンプレート
                ForEach(defaultTemplates.prefix(6 - min(3, viewModel.templates.count)), id: \.1) { emoji, title in
                    TemplateButton(
                        emoji: emoji.isEmpty ? "📝" : emoji, 
                        title: title.isEmpty ? NSLocalizedString("reminder", comment: "Default reminder title") : title
                    ) {
                        let finalTitle = title.isEmpty ? NSLocalizedString("reminder", comment: "Default reminder title") : title
                        pendingReminderTitle = finalTitle
                        // デフォルトテンプレートを使用した時にカスタムテンプレートとして保存
                        viewModel.findAndUseMatchingTemplate(for: finalTitle)
                        showingTimeSelector = true
                    }
                }
            }
        }
    }
}

struct TemplateButton: View {
    let emoji: String
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }) {
            VStack(spacing: 8) {
                Text(emoji.isEmpty ? "📝" : emoji)
                    .font(.title2)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                
                Text(title.isEmpty ? NSLocalizedString("reminder", comment: "Default title") : title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .accessibilityLabel("\(title) \(emoji)")
        .accessibilityHint("タップして\(title)のリマインダーを作成")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - Time Selection View

struct TimeSelectionView: View {
    let reminderTitle: String
    let viewModel: ReminderViewModel
    @Binding var isPresented: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var selectedDate = Date()
    @State private var useQuickTime = true
    
    // よく使う時間のプリセット（分後）
    private let quickTimes = [
        (title: "5分後", minutes: 5),
        (title: "15分後", minutes: 15),
        (title: "30分後", minutes: 30),
        (title: "1時間後", minutes: 60),
        (title: "2時間後", minutes: 120),
        (title: "明日の朝9時", minutes: -1) // 特別な値
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // ヘッダーとクローズボタン
                    HStack {
                        Spacer()
                        
                        Button(NSLocalizedString("close", comment: "")) {
                            isPresented = false
                        }
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                        .accessibilityLabel(NSLocalizedString("close", comment: ""))
                        .accessibilityAddTraits(.isButton)
                    }
                    
                    // リマインダーのタイトル表示
                    VStack(spacing: 12) {
                        Text("📝")
                            .font(.system(size: 48))
                        
                        Text(reminderTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                            .accessibilityLabel(NSLocalizedString("reminder_title", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, -40)
                    
                    // 時刻選択方法の切り替え
                    VStack(spacing: 16) {
                        Picker("選択方法", selection: $useQuickTime) {
                            Text(NSLocalizedString("quick_selection", comment: "")).tag(true)
                            Text(NSLocalizedString("detailed_settings", comment: "")).tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        
                        if useQuickTime {
                            // 簡単時刻選択
                            quickTimeSelection
                        } else {
                            // 詳細時刻選択
                            detailTimeSelection
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    // 簡単時刻選択
    private var quickTimeSelection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: horizontalSizeClass == .regular ? 3 : 2), spacing: 16) {
            ForEach(quickTimes, id: \.title) { timeOption in
                Button(action: {
                    createReminderWithQuickTime(timeOption)
                }) {
                    VStack(spacing: 12) {
                        Text(timeIcon(for: timeOption))
                            .font(.system(size: 32))
                        
                        Text(timeOption.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: false)
                .accessibilityLabel(timeOption.title)
                .accessibilityHint("タップして\(timeOption.title)にリマインダーを設定")
                .accessibilityAddTraits(.isButton)
            }
        }
    }
    
    // 詳細時刻選択
    private var detailTimeSelection: some View {
        VStack(spacing: 24) {
            Text(NSLocalizedString("choose_detailed_time", comment: ""))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            
            DatePicker(
                "時刻を選択",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color(.systemGray).opacity(0.2), radius: 4, x: 0, y: 2)
            
            Button(action: {
                createReminderWithCustomTime()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.body)
                    Text(NSLocalizedString("set_reminder_time", comment: ""))
                        .font(.body)
                        .fontWeight(.semibold)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .cornerRadius(16)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(NSLocalizedString("set_reminder_time", comment: ""))
            .accessibilityAddTraits(.isButton)
        }
    }
    
    // 時刻オプション用のアイコン
    private func timeIcon(for timeOption: (title: String, minutes: Int)) -> String {
        switch timeOption.minutes {
        case 5: return "⏰"
        case 15: return "⏱️"
        case 30: return "🕐"
        case 60: return "⏳"
        case 120: return "⏰"
        case -1: return "🌅" // 明日の朝
        default: return "⏰"
        }
    }
    
    // 簡単選択での リマインダー作成
    private func createReminderWithQuickTime(_ timeOption: (title: String, minutes: Int)) {
        let scheduledTime: Date
        
        if timeOption.minutes == -1 {
            // 明日の朝9時
            var tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            tomorrow = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? Date()
            scheduledTime = tomorrow
        } else {
            scheduledTime = Date().addingTimeInterval(TimeInterval(timeOption.minutes * 60))
        }
        
        viewModel.createReminder(title: reminderTitle, scheduledTime: scheduledTime)
        isPresented = false
    }
    
    // カスタム時刻でのリマインダー作成
    private func createReminderWithCustomTime() {
        viewModel.createReminder(title: reminderTitle, scheduledTime: selectedDate)
        isPresented = false
    }
}
