//
//  AddChecklistItemView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct AddChecklistItemView: View {
    let checklist: Checklist
    @ObservedObject var viewModel: ChecklistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // アイコン
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                // 説明
                VStack(spacing: 8) {
                    Text(LocalizedStringKey("add_new_item_title"))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(String(format: NSLocalizedString("add_item_to_checklist_desc", comment: ""), checklist.title ?? NSLocalizedString("checklist", comment: "")))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 入力フィールド
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("item_name_label"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField(String(localized: "item_name_placeholder"), text: $itemTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            if !itemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                addItem()
                            }
                        }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(LocalizedStringKey("add_item_navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "add")) {
                        addItem()
                    }
                    .disabled(itemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // 自動的にキーボードにフォーカス
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // フォーカスを設定（iOS 15+）
            }
        }
    }
    
    private func addItem() {
        let trimmedTitle = itemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        viewModel.addItem(to: checklist, title: trimmedTitle)
        HapticFeedback.notification(.success)
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let checklist = Checklist(context: context, title: NSLocalizedString("going_out_checklist", comment: ""), emoji: "🚶‍♂️")
    
    return AddChecklistItemView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}