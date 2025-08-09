//
//  SettingsView.swift
//  Remind!!!
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ReminderViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(version) (\(build))"
    }

    @State private var showingTemplateManager = false
    @State private var showingAbout = false
    @State private var showingPremium = false
    
    // Settings properties
    @AppStorage("darkModePreference") private var darkModePreference: ColorSchemePreference = .automatic
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("criticalAlertsEnabled") private var criticalAlertsEnabled = true
    @AppStorage("escalationInterval") private var escalationInterval: Double = 300 // 5 minutes
    @AppStorage("speechLanguage") private var speechLanguage = "auto"
    #if DEBUG
    @AppStorage("isPremium") private var debugForcePremium = false
    #endif
    
    var body: some View {
        NavigationStack {
            List {
                // App Info Section
                Section {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("app_name", comment: "App name"))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(String(format: NSLocalizedString("version_format", comment: "Version format"), appVersionString))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Premium Section
                Section {
                    Button(action: { showingPremium = true }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("プレミアム版")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    Button(action: { Task { await StoreKitService.shared.restorePurchases() } }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("購入を復元")
                        }
                    }
                }
                
                // Appearance Section
                Section {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(NSLocalizedString("dark_mode", comment: "Dark mode setting"))
                                .font(.body)
                            
                            Text(darkModePreference.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $darkModePreference) {
                            ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                                Text(preference.localizedDescription)
                                    .tag(preference)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text(NSLocalizedString("appearance", comment: "Appearance section"))
                }
                
                // Templates Section
                Section {
                    Button(action: {
                        showingTemplateManager = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.grid.3x2.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("templates", comment: "Templates section"))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: NSLocalizedString("templates_count", comment: "Templates count"), viewModel.templates.count))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("templates", comment: "Templates section"))
                }
                
                // Notifications Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text(NSLocalizedString("enable_notifications", comment: "Enable notifications"))
                        }
                    }
                    
                    if notificationsEnabled {
                        Toggle(isOn: $criticalAlertsEnabled) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(NSLocalizedString("critical_alerts", comment: "Critical alerts"))
                                    
                                    Text(NSLocalizedString("critical_alerts_subtitle", comment: "Critical alerts subtitle"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("escalation_intervals", comment: "Escalation intervals"))
                                
                                Text(String(format: NSLocalizedString("minutes_value", comment: "Minutes value"), Int(escalationInterval / 60)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Stepper("", value: $escalationInterval, in: 60...1800, step: 60)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text(NSLocalizedString("notifications", comment: "Notifications section"))
                }
                
                // Speech Recognition Section
                Section {
                    Picker(selection: $speechLanguage) {
                        Text(NSLocalizedString("automatic", comment: "Automatic language"))
                            .tag("auto")
                        Text(NSLocalizedString("english", comment: "English language"))
                            .tag("en-US")
                        Text(NSLocalizedString("japanese", comment: "Japanese language"))
                            .tag("ja-JP")
                    } label: {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("speech_recognition", comment: "Speech recognition"))
                                
                                Text(languageDisplayName(for: speechLanguage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(NSLocalizedString("speech_recognition", comment: "Speech recognition section"))
                }
                
                // About Section
                Section {
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            
                            Text(NSLocalizedString("about", comment: "About section"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("about", comment: "About section"))
                }
                
                #if DEBUG
                // Developer Section (Debug only)
                Section {
                    Toggle(isOn: $debugForcePremium) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("dev_force_premium", comment: "Developer force premium"))
                                Text(NSLocalizedString("dev_force_premium_desc", comment: "Developer force premium description"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: debugForcePremium) { _ in
                        HapticFeedback.selection()
                    }
                } header: {
                    Text(NSLocalizedString("developer", comment: "Developer section"))
                }
                #endif
            }
            .navigationTitle(NSLocalizedString("settings", comment: "Settings title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplateManager) {
            TemplateManagerView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPremium) { PremiumUpgradeView(viewModel: ChecklistViewModel()) }
        .preferredColorScheme(darkModePreference.colorScheme)
    }
    
    private func languageDisplayName(for code: String) -> String {
        switch code {
        case "auto":
            return NSLocalizedString("automatic", comment: "Automatic language")
        case "en-US":
            return NSLocalizedString("english", comment: "English language")
        case "ja-JP":
            return NSLocalizedString("japanese", comment: "Japanese language")
        default:
            return NSLocalizedString("automatic", comment: "Automatic language")
        }
    }
}

// MARK: - Color Scheme Preference
enum ColorSchemePreference: String, CaseIterable {
    case automatic = "automatic"
    case light = "light"
    case dark = "dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .automatic:
            return NSLocalizedString("automatic", comment: "Automatic color scheme")
        case .light:
            return NSLocalizedString("light", comment: "Light color scheme")
        case .dark:
            return NSLocalizedString("dark", comment: "Dark color scheme")
        }
    }
}

// MARK: - Template Manager View
struct TemplateManagerView: View {
    @ObservedObject var viewModel: ReminderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTemplate = false
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "rectangle.grid.3x2",
                        description: Text("Create your first custom template to get started")
                    )
                } else {
                    ForEach(viewModel.templates, id: \.objectID) { template in
                        TemplateRowView(template: template, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
            .navigationTitle(NSLocalizedString("templates", comment: "Templates"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("done", comment: "Done")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTemplate = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddTemplateView(viewModel: viewModel)
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = viewModel.templates[index]
            viewModel.deleteTemplate(template)
        }
    }
}

// MARK: - Template Row View
struct TemplateRowView: View {
    let template: ReminderTemplate
    @ObservedObject var viewModel: ReminderViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Text(template.emoji ?? "📝")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(String(format: NSLocalizedString("usage_count", comment: "Usage count"), template.usageCount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Template View
struct AddTemplateView: View {
    @ObservedObject var viewModel: ReminderViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedEmoji = "📝"
    
    private let availableEmojis = [
        "📝", "🧺", "💊", "🗑️", "📞", "🛒", "🚗",
        "🏠", "💻", "📚", "🎵", "🍽️", "🏃‍♂️", "💤",
        "⏰", "📅", "💡", "🔔", "⚡", "🎯", "🌟",
        "❤️", "🎉", "🌺", "🌙", "☀️", "🌈", "🔥"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(NSLocalizedString("template_title", comment: "Template title"), text: $title)
                } header: {
                    Text(NSLocalizedString("template_title", comment: "Template title"))
                }
                
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(availableEmojis, id: \.self) { emoji in
                            Button(action: {
                                selectedEmoji = emoji
                                HapticFeedback.selection()
                            }) {
                                Text(emoji)
                                    .font(.title)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ? Color.accentColor.opacity(0.3) : Color.clear)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedEmoji == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                            )
                                    )
                                    .scaleEffect(selectedEmoji == emoji ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedEmoji)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical)
                } header: {
                    Text(NSLocalizedString("template_emoji", comment: "Template emoji"))
                }
            }
            .navigationTitle(NSLocalizedString("add_template", comment: "Add template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "Cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("save", comment: "Save")) {
                        saveTemplate()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTemplate() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        viewModel.createTemplate(title: trimmedTitle, emoji: selectedEmoji)
        HapticFeedback.notification(.success)
        dismiss()
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon and Info
                    VStack(spacing: 16) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.accentColor)
                        
                        Text(NSLocalizedString("app_name", comment: "App name"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("A kind reminder app for everyone")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "mic.fill", title: "Voice Input", description: "Create reminders using voice recognition")
                        FeatureRow(icon: "bell.fill", title: "Smart Notifications", description: "Escalating reminders ensure you never forget")
                        FeatureRow(icon: "rectangle.grid.3x2.fill", title: "Custom Templates", description: "Quick access to your frequently used reminders")
                        FeatureRow(icon: "moon.fill", title: "Dark Mode", description: "Beautiful interface that adapts to your preference")
                        FeatureRow(icon: "globe", title: "Multilingual", description: "Supports Japanese and English")
                    }
                    .padding(.horizontal)
                    
                    // Credits
                    VStack(spacing: 8) {
                        Text("Created with ❤️ using SwiftUI")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text("© 2025 Remind!!!")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        #if DEBUG
                        Text("Current Language: \(Locale.current.languageCode ?? "unknown")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        #endif
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("about", comment: "About"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("done", comment: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView(viewModel: ReminderViewModel())
}