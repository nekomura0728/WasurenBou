//
//  ContentView.swift
//  Remind!!! Watch App
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var viewModel = WatchReminderViewModel()
    @State private var showingVoiceInput = false
    @State private var showingTemplates = false
    @State private var crownRotation: Double = 0
    
    var body: some View {
        NavigationStack {
            TabView {
                // メイン画面
                mainView
                    .tag(0)
                
                // リマインダー一覧
                remindersListView
                    .tag(1)
                
                // テンプレート一覧
                templatesView
                    .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Main View
    private var mainView: some View {
        VStack(spacing: 12) {
            // アプリ名
            Text("Remind!!!")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.accent)
            
            // 今日のリマインダー数
            VStack(spacing: 4) {
                Text("\(viewModel.todayRemindersCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(viewModel.todayRemindersCount == 1 ? "reminder" : "reminders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .animation(.spring(), value: viewModel.todayRemindersCount)
            
            // アクションボタン
            VStack(spacing: 8) {
                // 音声入力ボタン
                Button(action: {
                    showingVoiceInput = true
                    WKInterfaceDevice.current().play(.click)
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Voice")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                // テンプレートボタン
                Button(action: {
                    showingTemplates = true
                    WKInterfaceDevice.current().play(.click)
                }) {
                    HStack {
                        Image(systemName: "rectangle.grid.2x2")
                        Text("Templates")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingTemplates) {
            TemplateSelectionView(viewModel: viewModel)
        }
    }
    
    // MARK: - Reminders List View
    private var remindersListView: some View {
        VStack {
            if viewModel.todayReminders.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("All Done!")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("No reminders today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.todayReminders, id: \.objectID) { reminder in
                        WatchReminderRow(reminder: reminder, viewModel: viewModel)
                    }
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Templates View
    private var templatesView: some View {
        VStack {
            if viewModel.templates.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.grid.2x2")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No Templates")
                        .font(.headline)
                    
                    Text("Create templates on iPhone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    #if DEBUG
                    // Simulator テスト用
                    Button("Test iPhone Sync") {
                        viewModel.requestDataFromiPhone()
                        WKInterfaceDevice.current().play(.click)
                    }
                    .font(.caption2)
                    .padding(.top)
                    #endif
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.templates, id: \.objectID) { template in
                        WatchTemplateRow(template: template, viewModel: viewModel)
                    }
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Watch Reminder Row
struct WatchReminderRow: View {
    let reminder: Reminder
    @ObservedObject var viewModel: WatchReminderViewModel
    @State private var isCompleting = false
    
    private var urgencyColor: Color {
        let timeLeft = reminder.scheduledTime?.timeIntervalSinceNow ?? 0
        if timeLeft <= 0 { return .red }
        if timeLeft <= 300 { return .orange } // 5分以内
        return .green
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 緊急度インジケーター
            Circle()
                .fill(urgencyColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title ?? "")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(reminder.scheduledTime ?? Date(), style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 完了ボタン
            Button(action: {
                completeReminder()
            }) {
                Image(systemName: isCompleting ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleting ? .green : .blue)
                    .font(.title3)
            }
            .disabled(isCompleting)
        }
        .padding(.vertical, 2)
    }
    
    private func completeReminder() {
        isCompleting = true
        WKInterfaceDevice.current().play(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.completeReminder(reminder)
            isCompleting = false
        }
    }
}

// MARK: - Watch Template Row
struct WatchTemplateRow: View {
    let template: ReminderTemplate
    @ObservedObject var viewModel: WatchReminderViewModel
    @State private var showingTimePicker = false
    
    var body: some View {
        Button(action: {
            showingTimePicker = true
            WKInterfaceDevice.current().play(.click)
        }) {
            HStack(spacing: 8) {
                Text(template.emoji ?? "📝")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title ?? "")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    Text("Used \(template.usageCount) times")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTimePicker) {
            WatchTimePickerView(
                title: template.title ?? "",
                emoji: template.emoji ?? "📝",
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Voice Input View
struct VoiceInputView: View {
    @ObservedObject var viewModel: WatchReminderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var transcription = ""
    @State private var showingSuccess = false
    
    var body: some View {
        VStack(spacing: 16) {
            // タイトル
            Text("Voice Input")
                .font(.headline)
                .fontWeight(.bold)
            
            // 音声入力ボタン
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isRecording ? .red : .blue)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isRecording)
            }
            
            // 状態テキスト
            Text(isRecording ? "Recording..." : "Tap to speak")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 認識結果
            if !transcription.isEmpty {
                Text(transcription)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // 成功表示
            if showingSuccess {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Created!")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
    }
    
    private func startRecording() {
        isRecording = true
        transcription = ""
        WKInterfaceDevice.current().play(.start)
        
        // Simulator用のデモデータ（複数パターン）
        let demoTranscriptions = [
            "5分後に薬を飲む",
            "30分後に洗濯物取り込む", 
            "1時間後に母に電話する",
            "明日の朝にゴミを出す",
            "15分後に牛乳を買いに行く"
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            transcription = demoTranscriptions.randomElement() ?? "リマインダーを作成"
            stopRecording()
        }
    }
    
    private func stopRecording() {
        isRecording = false
        WKInterfaceDevice.current().play(.stop)
        
        if !transcription.isEmpty {
            // リマインダーを作成
            let scheduledTime = Date().addingTimeInterval(300) // 5分後
            viewModel.createReminder(title: transcription, scheduledTime: scheduledTime)
            
            showingSuccess = true
            WKInterfaceDevice.current().play(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

// MARK: - Time Picker View
struct WatchTimePickerView: View {
    let title: String
    let emoji: String
    @ObservedObject var viewModel: WatchReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMinutes: Double = 15
    @State private var showingSuccess = false
    
    private let quickTimes = [5, 15, 30, 60, 120] // minutes
    
    var body: some View {
        VStack(spacing: 12) {
            // テンプレート表示
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.largeTitle)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if !showingSuccess {
                // 時間選択
                VStack(spacing: 8) {
                    Text("In \(Int(selectedMinutes)) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // スライダー
                    VStack {
                        Slider(value: $selectedMinutes, in: 5...120, step: 5)
                        
                        HStack {
                            Text("5min")
                                .font(.caption2)
                            Spacer()
                            Text("2hr")
                                .font(.caption2)
                        }
                    }
                }
                
                // 作成ボタン
                Button(action: createReminder) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            } else {
                // 成功表示
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("Reminder Created!")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
    }
    
    private func createReminder() {
        let scheduledTime = Date().addingTimeInterval(selectedMinutes * 60)
        viewModel.createReminder(title: title, scheduledTime: scheduledTime)
        
        showingSuccess = true
        WKInterfaceDevice.current().play(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

#Preview {
    ContentView()
}