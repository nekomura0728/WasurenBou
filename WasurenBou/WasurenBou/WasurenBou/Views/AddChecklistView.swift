//
//  AddChecklistView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct AddChecklistView: View {
    @ObservedObject var viewModel: ChecklistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var selectedEmoji = "📋"
    @State private var selectedTemplate: ChecklistTemplate?
    
    private let availableEmojis = [
        "📋", "🚶‍♂️", "✈️", "💼", "🏠", "🛒",
        "🏥", "🎒", "🚗", "🏫", "👔", "🎭"
    ]
    
    private let templates: [ChecklistTemplate] = [
        ChecklistTemplate(
            title: NSLocalizedString("going_out_checklist", comment: ""),
            emoji: "🚶‍♂️",
            items: [
                NSLocalizedString("item_smartphone", comment: ""),
                NSLocalizedString("item_wallet", comment: ""),
                NSLocalizedString("item_house_keys", comment: ""),
                NSLocalizedString("item_handkerchief", comment: ""),
                NSLocalizedString("item_mask", comment: "")
            ]
        ),
        ChecklistTemplate(
            title: NSLocalizedString("travel_checklist", comment: ""),
            emoji: "✈️",
            items: [
                NSLocalizedString("item_passport", comment: ""),
                NSLocalizedString("item_tickets", comment: ""),
                NSLocalizedString("item_charger", comment: ""),
                NSLocalizedString("item_clothes", comment: ""),
                NSLocalizedString("item_toiletries", comment: "")
            ]
        ),
        ChecklistTemplate(
            title: NSLocalizedString("work_checklist", comment: ""),
            emoji: "💼",
            items: [
                NSLocalizedString("item_laptop", comment: ""),
                NSLocalizedString("item_documents", comment: ""),
                NSLocalizedString("item_business_cards", comment: ""),
                NSLocalizedString("item_stationery", comment: ""),
                NSLocalizedString("item_employee_id", comment: "")
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // テンプレート選択
                    templateSelectionSection
                    
                    // カスタマイズセクション
                    customizationSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("add_checklist", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("create_button", comment: "")) {
                        createChecklist()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Template Selection
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("select_template", comment: ""))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 1), spacing: 12) {
                ForEach(templates, id: \.title) { template in
                    TemplateRow(
                        template: template,
                        isSelected: selectedTemplate?.title == template.title,
                        onTap: { selectTemplate(template) }
                    )
                }
            }
            
            // カスタムテンプレート
            TemplateRow(
                template: ChecklistTemplate(title: NSLocalizedString("custom_template", comment: ""), emoji: "✏️", items: []),
                isSelected: selectedTemplate == nil,
                onTap: { selectCustomTemplate() }
            )
        }
    }
    
    // MARK: - Customization Section
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("customize", comment: ""))
                .font(.headline)
                .fontWeight(.semibold)
            
            // タイトル入力
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("title_label", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField(NSLocalizedString("checklist_placeholder", comment: ""), text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // 絵文字選択
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("emoji_label", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(availableEmojis, id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(selectedEmoji == emoji ? Color.accentColor.opacity(0.3) : Color.clear)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedEmoji == emoji ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                                        )
                                )
                                .scaleEffect(selectedEmoji == emoji ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3), value: selectedEmoji)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // プレミアム機能の案内（削除）
            // if !viewModel.isPremium {
            //     premiumFeaturePrompt
            // }
        }
    }
    
    // MARK: - Premium Feature Prompt（削除）
    // private var premiumFeaturePrompt: some View {
    //     EmptyView()
    // }
    
    // MARK: - Actions
    private func selectTemplate(_ template: ChecklistTemplate) {
        selectedTemplate = template
        title = template.title
        selectedEmoji = template.emoji
    }
    
    private func selectCustomTemplate() {
        selectedTemplate = nil
        title = ""
        selectedEmoji = "📋"
    }
    
    private func createChecklist() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        viewModel.createChecklist(title: trimmedTitle, emoji: selectedEmoji)
        
        // 選択したテンプレートのアイテムを追加
        if let template = selectedTemplate {
            // テンプレートアイテムの追加は ChecklistViewModel.createChecklist 内で処理
        }
        
        HapticFeedback.notification(.success)
        dismiss()
    }
}

// MARK: - Template Row
struct TemplateRow: View {
    let template: ChecklistTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(template.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if !template.items.isEmpty {
                        Text(template.items.prefix(3).joined(separator: "、") + (template.items.count > 3 ? "..." : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.systemCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Checklist Template Model
struct ChecklistTemplate {
    let title: String
    let emoji: String
    let items: [String]
}

#Preview {
    AddChecklistView(viewModel: ChecklistViewModel())
}