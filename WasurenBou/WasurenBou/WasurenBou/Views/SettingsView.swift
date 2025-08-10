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
                            Text(LocalizedStringKey("app_name"))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(String(format: String(localized: "version_format"), appVersionString))
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
                            Text(LocalizedStringKey("premium_version"))
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
                            Text(LocalizedStringKey("restore_purchases"))
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
                            Text(LocalizedStringKey("dark_mode"))
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
                    Text(LocalizedStringKey("appearance"))
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
                                Text(LocalizedStringKey("templates"))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: String(localized: "templates_count"), viewModel.templates.count))
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
                    Text(LocalizedStringKey("templates"))
                }
                
                // Notifications Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text(LocalizedStringKey("enable_notifications"))
                        }
                    }
                    
                    if notificationsEnabled {
                        Toggle(isOn: $criticalAlertsEnabled) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizedStringKey("critical_alerts"))
                                    
                                    Text(LocalizedStringKey("critical_alerts_subtitle"))
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
                                Text(LocalizedStringKey("escalation_intervals"))
                                
                                Text(String(format: String(localized: "minutes_value"), Int(escalationInterval / 60)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Stepper("", value: $escalationInterval, in: 60...1800, step: 60)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("notifications"))
                }
                
                // Speech Recognition Section
                Section {
                    Picker(selection: $speechLanguage) {
                        Text(LocalizedStringKey("automatic"))
                            .tag("auto")
                        Text(LocalizedStringKey("english"))
                            .tag("en-US")
                        Text(LocalizedStringKey("japanese"))
                            .tag("ja-JP")
                    } label: {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey("speech_recognition"))
                                
                                Text(languageDisplayName(for: speechLanguage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("speech_recognition"))
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
                            
                            Text(LocalizedStringKey("about"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        openSupportURL()
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(LocalizedStringKey("support"))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("about"))
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
                                Text(LocalizedStringKey("dev_force_premium"))
                                Text(LocalizedStringKey("dev_force_premium_desc"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: debugForcePremium) { _ in
                        HapticFeedback.selection()
                    }
                } header: {
                    Text(LocalizedStringKey("developer"))
                }
                #endif
            }
            .navigationTitle(LocalizedStringKey("settings"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "done")) {
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
            return String(localized: "automatic")
        case "en-US":
            return String(localized: "english")
        case "ja-JP":
            return String(localized: "japanese")
        default:
            return String(localized: "automatic")
        }
    }
    
    private func openSupportURL() {
        guard let url = URL(string: "https://nekomura0728.github.io/WasurenBou/support.html") else {
            return
        }
        UIApplication.shared.open(url)
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
            return String(localized: "automatic")
        case .light:
            return String(localized: "light")
        case .dark:
            return String(localized: "dark")
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
                        LocalizedStringKey("no_templates"),
                        systemImage: "rectangle.grid.3x2",
                        description: Text(LocalizedStringKey("no_templates_description"))
                    )
                } else {
                    ForEach(viewModel.templates, id: \.objectID) { template in
                        TemplateRowView(template: template, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
            .navigationTitle(LocalizedStringKey("templates"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("done")) {
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
                
                Text(String(format: String(localized: "usage_count"), template.usageCount))
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
                    TextField(LocalizedStringKey("template_title"), text: $title)
                } header: {
                    Text(LocalizedStringKey("template_title"))
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
                    Text(LocalizedStringKey("template_emoji"))
                }
            }
            .navigationTitle(LocalizedStringKey("add_template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("save")) {
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
                        
                        Text(LocalizedStringKey("app_name"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(String(format: NSLocalizedString("version_format", comment: ""), "1.0.0"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedStringKey("app_description"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStringKey("features"))
                            .font(.headline)
                        
                        FeatureRow(icon: "mic.fill", title: NSLocalizedString("feature_voice_input", comment: ""), description: NSLocalizedString("feature_voice_input_desc", comment: ""))
                        FeatureRow(icon: "bell.fill", title: NSLocalizedString("feature_smart_notifications", comment: ""), description: NSLocalizedString("feature_smart_notifications_desc", comment: ""))
                        FeatureRow(icon: "rectangle.grid.3x2.fill", title: NSLocalizedString("feature_custom_templates", comment: ""), description: NSLocalizedString("feature_custom_templates_desc", comment: ""))
                        FeatureRow(icon: "moon.fill", title: NSLocalizedString("feature_dark_mode", comment: ""), description: NSLocalizedString("feature_dark_mode_desc", comment: ""))
                        FeatureRow(icon: "globe", title: NSLocalizedString("feature_multilingual", comment: ""), description: NSLocalizedString("feature_multilingual_desc", comment: ""))
                    }
                    .padding(.horizontal)
                    
                    // Credits
                    VStack(spacing: 8) {
                        Text(LocalizedStringKey("created_with_love"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedStringKey("copyright"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        #if DEBUG
                        Text(String(format: NSLocalizedString("current_language", comment: ""), Locale.current.languageCode ?? "unknown"))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        #endif
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedStringKey("about"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("done")) {
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