//
//  Untitled.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

struct AddCardView: View {
    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var contxt

    @State private var content: String = ""
    @State private var showNotificationPicker = false
    @State private var selectedNotificationTime: Date = Date()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                contentEditorView
                notificationTimeView
                notificationButtonsView
            }
            .padding()
            .navigationTitle("新建阅读卡片")
            .toolbar {
                #if os(iOS)
                    navigationBarButtons
                #endif
            }
            .sheet(isPresented: $showNotificationPicker) {
                notificationPickerView
            }
        }
    }

    // MARK: - Views
    private var contentEditorView: some View {
        TextEditor(text: $content)
            .font(.body)
            #if os(macOS)
                .frame(height: 150)
            #else
                .frame(maxHeight: .infinity)
            #endif
            .textEditorPadding()
            .cornerRadius(8)
    }

    private var notificationTimeView: some View {
        Text(selectedNotificationTime.formatted(date: .abbreviated, time: .shortened))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationButtonsView: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .foregroundColor(.blue)
                .symbolEffect(.bounce, value: 1)
            tomorrowMorningButton
            tonightButton
            customTimeButton
            Spacer()
        }
    }

    private var tomorrowMorningButton: some View {
        Button(action: setTomorrowMorning) {
            Text("明天上午")
        }
        .buttonStyle(BorderedButtonStyle())
    }

    private var tonightButton: some View {
        Button(action: setTonight) {
            Text("今晚")
        }
        .buttonStyle(BorderedButtonStyle())
    }

    private var customTimeButton: some View {
        Button(action: { showNotificationPicker.toggle() }) {
            Text("自定义")
        }
        .buttonStyle(BorderedButtonStyle())
    }
#if os(iOS)
    private var navigationBarButtons: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveCard()
                    dismiss()
                }
                .disabled(content.isEmpty)
            }
            
        }
    }
#endif

    private var notificationPickerView: some View {
        NavigationStack {
            DatePicker(
                "选择提醒时间",
                selection: $selectedNotificationTime,
                in: Date()...
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("设置提醒")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showNotificationPicker = false
                    }
                }
#endif
            }
        }
    }

    // MARK: - Actions
    private func saveCard() {
        let card = ReadingCardModel(content: content, reminderAt: selectedNotificationTime)
        contxt.insert(card)
    }
    
    private func setTomorrowMorning() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let components = DateComponents(hour: 9, minute: 0)
        selectedNotificationTime =
            Calendar.current.date(
                bySettingHour: components.hour!,
                minute: components.minute!,
                second: 0,
                of: tomorrow
            ) ?? Date()
    }

    private func setTonight() {
        let components = DateComponents(hour: 20, minute: 0)
        selectedNotificationTime =
            Calendar.current.date(
                bySettingHour: components.hour!,
                minute: components.minute!,
                second: 0,
                of: Date()
            ) ?? Date()
    }
}

#Preview {
    AddCardView()
}
