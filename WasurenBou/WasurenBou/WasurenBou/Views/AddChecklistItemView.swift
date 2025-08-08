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
                    Text("新しいアイテムを追加")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(checklist.title ?? "チェックリスト") にアイテムを追加します")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 入力フィールド
                VStack(alignment: .leading, spacing: 8) {
                    Text("アイテム名")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("例：スマホ", text: $itemTitle)
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
            .navigationTitle("アイテム追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
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
    let checklist = Checklist(context: context, title: "外出用", emoji: "🚶‍♂️")
    
    return AddChecklistItemView(
        checklist: checklist,
        viewModel: ChecklistViewModel()
    )
}