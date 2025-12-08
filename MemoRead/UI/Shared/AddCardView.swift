//
//  Untitled.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

// MARK: - Time Option
private enum TimeOption {
    case tomorrowMorning
    case tonight
    case custom
}

struct AddCardView: View {
    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var contxt
    
    @AppStorage("enableNotification") private var enableNotification = true
    
    @State private var content: String = ""
    @State private var showNotificationPicker = false
    @State private var selectedNotificationTime: Date = Date()
    @State private var selectedTimeOption: TimeOption = .custom
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                topHandle
                header
                contentEditorView
                notificationTimeView
                bottomToolbar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(AddCardStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .sheet(isPresented: $showNotificationPicker) {
                notificationPickerView
            }
        }
    }
    
    // MARK: - Views
    private var topHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 40, height: 8)
            .padding(.top, 4)
    }
    
    private var header: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
            
            Spacer()
            
            Text("New Note")
                .font(.title2.bold())
            
            Spacer()
            
            Button("Save") {
                saveCard()
                dismiss()
            }
            .disabled(content.isEmpty)
            .foregroundColor(content.isEmpty ? .gray.opacity(0.6) : .primary)
        }
    }
    
    private var contentEditorView: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $content)
                .font(.body)
#if os(macOS)
                .frame(height: 150)
#else
                .frame(maxHeight: .infinity, alignment: .topLeading)
#endif
                .textEditorPadding()
                .background(Color.white.opacity(0.6))
                .cornerRadius(16)
            
            if content.isEmpty {
                Text("What's on your mind?")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
            }
        }
    }
    
    private var notificationTimeView: some View {
        HStack {
            Image(systemName: "bell")
                .foregroundColor(AddCardStyle.accent)
            Text(selectedNotificationTime.formatted(date: .abbreviated, time: .shortened))
                .foregroundColor(.gray)
            Spacer()
            reminderQuickActions
        }
        .font(.subheadline)
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            HStack(spacing: 16) {
                iconButton(system: "photo.on.rectangle") {
                    handleAddImage()
                }
                iconButton(system: "camera") {
                    handleTakePhoto()
                }
            }
            
            Divider()
                .frame(height: 32)
            
            Button(action: handleAutoTag) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(AddCardStyle.accent)
                    Text("Auto-tag")
                        .foregroundColor(AddCardStyle.accent)
                        .font(.headline)
                }
            }
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    private var reminderQuickActions: some View {
        HStack(spacing: 8) {
            tomorrowMorningButton
            tonightButton
            customTimeButton
        }
    }
    
    private var tomorrowMorningButton: some View {
        Button(action: {
            selectedTimeOption = .tomorrowMorning
            setTomorrowMorning()
        }) {
            Text("Tomorrow Morning")
        }
        .buttonStyle(TimeButtonStyle(isSelected: selectedTimeOption == .tomorrowMorning))
    }
    
    private var tonightButton: some View {
        Button(action: {
            selectedTimeOption = .tonight
            setTonight()
        }) {
            Text("Tonight")
        }
        .buttonStyle(TimeButtonStyle(isSelected: selectedTimeOption == .tonight))
    }
    
    private var customTimeButton: some View {
        Button(action: {
            selectedTimeOption = .custom
            showNotificationPicker.toggle()
        }) {
            Text("Custom")
        }
        .buttonStyle(TimeButtonStyle(isSelected: selectedTimeOption == .custom))
    }
#if os(iOS)
    private var navigationBarButtons: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.gray)
            }
            ToolbarItem(placement: .principal) {
                Text("New Note")
                    .font(.title2.bold())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveCard()
                    dismiss()
                }
                .disabled(content.isEmpty)
                .foregroundColor(content.isEmpty ? .gray.opacity(0.6) : .primary)
            }
        }
    }
#endif
    
    private var notificationPickerView: some View {
        NavigationStack {
            DatePicker(
                "Reminder Time",
                selection: $selectedNotificationTime,
                in: Date()...
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Reminder Time")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showNotificationPicker = false
                    }
                }
#endif
            }
        }
    }
    
    // MARK: - macOS Navigation Bar Buttons
#if os(macOS)
    private var macOSNavigationBarButtons: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCard()
                    dismiss()
                }
                .disabled(content.isEmpty)
            }
        }
    }
#endif
    
    // MARK: - Actions
    private func handleAddImage() {
        // TODO: 实现从相册选择图片的逻辑
        // 这里可以弹出 PhotosPicker 或 UIImagePickerController
    }
    
    private func handleTakePhoto() {
        // TODO: 实现拍照逻辑
        // 这里可以弹出相机控制器
    }
    
    private func handleAutoTag() {
        // TODO: 实现自动打标签逻辑
    }
    
    private func saveCard() {
        let card = ReadingCardModel(
            content: content,
            reminderAt: selectedNotificationTime
        )
        contxt.insert(card)
        
        if enableNotification {
            NotificationManager.shared.scheduleNotification(for: card)
        }
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

#if os(iOS)
// MARK: - Helpers
private func iconButton(system: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: system)
            .font(.title3)
            .foregroundColor(AddCardStyle.accent)
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
#endif

// MARK: - Styles
private enum AddCardStyle {
    static let accent = Color.purple
    static let background = Color.white.opacity(0.9)
}

#Preview {
    AddCardView()
}
