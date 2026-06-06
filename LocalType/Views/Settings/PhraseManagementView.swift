import SwiftUI

struct PhraseManagementView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddSheet = false
    @State private var editingPhrase: QuickPhrase?
    @State private var labelText = ""
    @State private var contentText = ""
    @State private var showDeleteConfirm: QuickPhrase?

    var body: some View {
        List {
            if appState.quickPhrases.isEmpty {
                ContentUnavailableView(
                    "没有快捷短语",
                    systemImage: "text.bubble",
                    description: Text("点击右上角添加常用短语")
                )
            } else {
                ForEach(appState.quickPhrases) { phrase in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.label)
                            .font(.body.weight(.medium))
                        Text(phrase.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        labelText = phrase.label
                        contentText = phrase.content
                        editingPhrase = phrase
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            showDeleteConfirm = phrase
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("快捷短语")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    labelText = ""
                    contentText = ""
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            phraseSheet(title: "添加短语", saveAction: {
                appState.addQuickPhrase(label: labelText, content: contentText)
                showAddSheet = false
            })
        }
        .alert("编辑短语", isPresented: .init(
            get: { editingPhrase != nil },
            set: { if !$0 { editingPhrase = nil } }
        )) {
            TextField("标签", text: $labelText)
            TextField("内容", text: $contentText)
            Button("取消", role: .cancel) { editingPhrase = nil }
            Button("保存") {
                if let phrase = editingPhrase {
                    appState.updateQuickPhrase(id: phrase.id, label: labelText, content: contentText)
                }
                editingPhrase = nil
            }
            .disabled(labelText.trimmingCharacters(in: .whitespaces).isEmpty || contentText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .alert("确认删除", isPresented: .init(
            get: { showDeleteConfirm != nil },
            set: { if !$0 { showDeleteConfirm = nil } }
        )) {
            Button("取消", role: .cancel) { showDeleteConfirm = nil }
            Button("删除", role: .destructive) {
                if let phrase = showDeleteConfirm {
                    appState.removeQuickPhrase(id: phrase.id)
                }
                showDeleteConfirm = nil
            }
        } message: {
            if let phrase = showDeleteConfirm {
                Text("确定要删除「\(phrase.label)」吗？")
            }
        }
    }

    private func phraseSheet(title: String, saveAction: @escaping () -> Void) -> some View {
        NavigationStack {
            Form {
                Section("标签") {
                    TextField("例如：问候", text: $labelText)
                }
                Section("内容") {
                    TextField("例如：你好！", text: $contentText, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { saveAction() }
                        .disabled(labelText.trimmingCharacters(in: .whitespaces).isEmpty || contentText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
