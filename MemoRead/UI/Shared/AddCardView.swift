//
//  Untitled.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI
#if os(iOS)
import PhotosUI
#endif

#if os(iOS)

// MARK: - Time Option
private enum TimeOption {
    case tomorrowMorning
    case tonight
    case custom
}

#endif
struct AddCardView: View {
    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var contxt
    
    @AppStorage("enableNotification") private var enableNotification = true
    
    @State private var content: String = ""
    @State private var showNotificationPicker = false
    @State private var selectedNotificationTime: Date = Date()
    @State private var selectedTimeOption: TimeOption = .custom
#if os(iOS)
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
#endif
    
    // MARK: - Computed Properties
    private var hasValidContent: Bool {
#if os(iOS)
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
#else
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
#endif
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
#if os(iOS)
                    if selectedImage != nil {
                        imagePreviewView
                    }
#endif
                    contentEditorView
                    notificationTimeView
                    bottomToolbar
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AddCardStyle.background)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .sheet(isPresented: $showNotificationPicker) {
                notificationPickerView
            }
#if os(iOS)
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $photoItem,
                matching: .images
            )
            .sheet(isPresented: $showCameraPicker) {
                CameraPickerView { image in
                    applySelectedImage(image)
                    showCameraPicker = false
                }
            }
            .onChange(of: photoItem) { _, newValue in
                Task { await loadSelectedPhoto(newValue) }
            }
#endif
        }
    }
    
    // MARK: - Views
    
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
            .disabled(!hasValidContent)
            .foregroundColor(hasValidContent ? AddCardStyle.accent : .gray.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(hasValidContent ? AddCardStyle.accent.opacity(0.1) : Color.clear)
            .cornerRadius(20)
        }
    }
    
#if os(iOS)
    private var imagePreviewView: some View {
        ZStack(alignment: .topTrailing) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                
                Button(action: {
                    selectedImage = nil
                    // 如果content是图片数据，清空它
                    if content.isValidImageData {
                        content = ""
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(8)
            }
        }
    }
#endif
    
    private var contentEditorView: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $content)
                .font(.body)
#if os(macOS)
                .frame(height: 150)
#else
                .frame(minHeight: 100)
#endif
                .textEditorPadding()
                .background(Color.white.opacity(0.6))
                .cornerRadius(16)
            
            if content.isEmpty {
                Text(placeholderText)
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var placeholderText: String {
#if os(iOS)
        if selectedImage != nil {
            return "Add your notes here..."
        }
#endif
        return "What's on your mind?"
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
#if os(iOS)
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
#endif
            
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
        #if os(iOS)
        showPhotoPicker = true
        #endif
    }
    
    private func handleTakePhoto() {
        #if os(iOS)
        showCameraPicker = true
        #endif
    }
    
    private func handleAutoTag() {
        // TODO: 实现自动打标签逻辑
    }
    
    private func saveCard() {
        var finalContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
#if os(iOS)
        // 如果有选中的图片，将图片转换为base64并保存
        if let image = selectedImage {
            guard let imageData = image.compressedData(compressionQuality: 0.8) else {
                return
            }
            let base64String = imageData.base64EncodedString()
            
            // 如果还有文本内容，将文本追加到图片数据后面
            if !finalContent.isEmpty {
                finalContent = base64String + "\n" + finalContent
            } else {
                finalContent = base64String
            }
        }
#endif
        
        // 确保内容不为空
        guard !finalContent.isEmpty else { return }
        
        let card = ReadingCardModel(
            content: finalContent,
            reminderAt: selectedNotificationTime
        )
        contxt.insert(card)
        
        if enableNotification {
            NotificationManager.shared.scheduleNotification(for: card)
        }
        
        // 同步到其他设备
        #if os(iOS)
        MultipeerSyncService.shared.syncCardToPeers(card, modelContext: contxt)
        #endif
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
    
#if os(iOS)
    // MARK: - Image helpers
    private func applySelectedImage(_ image: UIImage) {
        selectedImage = image
        // 保留原有的文本内容，不覆盖
    }
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    applySelectedImage(image)
                }
            }
        } catch {
            print("Photo load error: \(error.localizedDescription)")
        }
    }
#endif
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

// MARK: - Camera Picker (UIKit)
private struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        
        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
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

