//
//  ChecklistView.swift
//  忘れないアプリ
//
//  Created by Claude on 2025/08/07.
//

import SwiftUI

struct ChecklistView: View {
    @ObservedObject var viewModel: ChecklistViewModel
    @State private var showingAddChecklist = false
    @State private var showingUpgradePrompt = false
    @State private var selectedChecklistForDetail: Checklist?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // チェックリスト一覧
                if viewModel.checklists.isEmpty {
                    emptyStateView
                } else {
                    checklistsListView
                }
                
                // 広告エリア（無料版のみ）
                if !viewModel.isPremium {
                    AdMobBannerView()
                        .frame(height: 50)
                }
            }
            .navigationTitle("チェックリスト")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addChecklistTapped) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddChecklist) {
            AddChecklistView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            PremiumUpgradeView(viewModel: viewModel)
        }
        .sheet(item: $selectedChecklistForDetail) { checklist in
            ChecklistDetailView(checklist: checklist, viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadChecklists()
            AdMobService.shared.initialize()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("チェックリストがありません")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("最初のチェックリストを作成してみましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: addChecklistTapped) {
                HStack {
                    Image(systemName: "plus")
                    Text("チェックリストを作成")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Checklists List
    private var checklistsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.checklists, id: \.objectID) { checklist in
                    ChecklistRowView(
                        checklist: checklist,
                        onTap: { 
                            viewModel.selectChecklist(checklist)
                            selectedChecklistForDetail = checklist
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    
    // MARK: - Actions
    private func addChecklistTapped() {
        // 無料版は3つまで制限
        if !viewModel.isPremium && viewModel.checklists.count >= 3 {
            showingUpgradePrompt = true
        } else {
            showingAddChecklist = true
        }
    }
}

// MARK: - Checklist Row View
struct ChecklistRowView: View {
    let checklist: Checklist
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 絵文字
                Text(checklist.emoji ?? "📋")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(checklist.title ?? "チェックリスト")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // 完了状況
                        Text("\(Int(checklist.completionPercentage * 100))% 完了")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if checklist.isLocationBased {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                Text("GPS")
                            }
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // 進行状況サークル
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    
                    Circle()
                        .trim(from: 0, to: checklist.completionPercentage)
                        .stroke(
                            checklist.isCompleted ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    if checklist.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .frame(width: 32, height: 32)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding()
            .background(Color.systemCardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ChecklistView(viewModel: ChecklistViewModel())
}