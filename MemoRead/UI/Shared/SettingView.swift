//
//  SettingView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

// MARK: - Setting Section Model
struct SettingSection: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    
    static let allSections: [SettingSection] = [
        .init(id: "sync", title: "Sync", icon: "arrow.triangle.2.circlepath"),
        .init(id: "notification", title: "Notification", icon: "bell"),
        .init(id: "ai_model", title: "AI Model", icon: "brain.head.profile"),
        .init(id: "appearance", title: "Appearance", icon: "paintbrush"),
        .init(id: "data", title: "Data Management", icon: "externaldrive"),
        .init(id: "about", title: "About", icon: "info.circle")
    ]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SettingView: View {
    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("enableAutoSync") private var enableAutoSync = true
    @AppStorage("enableNotification") private var enableNotification = true
    @AppStorage("app_appearance") private var selectedAppearance: Appearance = .automatic
    @State private var showClearDataAlert = false
    @AppStorage("lastSyncTime") private var lastSyncTime = Date()
    @State private var isClearing = false
    @State private var showAIModelList = false
    
#if os(macOS)
    @State private var selectedSection: SettingSection? = SettingSection.allSections.first
    private let minWidth: CGFloat = 600
    private let minHeight: CGFloat = 400
    private let sidebarWidth: CGFloat = 200
#endif
    
    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    // MARK: - View Body
    var body: some View {
#if os(iOS)
        NavigationStack {
            mainContentiOS
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { dismissButton }
                .sheet(isPresented: $showAIModelList) {
                    AIModelListView()
                }
        }
#else
        NavigationStack {
            mainContentmacOS
            .alert(isPresented: $showClearDataAlert) {
                clearDataAlert
            }
            .toolbar { dismissButton }
            .sheet(isPresented: $showAIModelList) {
                AIModelListView()
            }
        }
#endif
    }
    
    // MARK: - iOS Main Content
    private var dismissButton: some ToolbarContent {
#if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") { dismiss() }
        }
#else
        ToolbarItem(placement: .cancellationAction) {
            Button("Done") { dismiss() }
        }
#endif
    }
}

// MARK: - Content Views
private extension SettingView {
    private var mainContentiOS: some View {
        Form {
            ForEach(SettingSection.allSections) { section in
                Section(section.title) {
                    sectionContent(for: section)
                }
            }
        }
        .alert(isPresented: $showClearDataAlert) {
            clearDataAlert
        }
    }
    
    private var mainContentmacOS: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(SettingSection.allSections) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        Label(section.title, systemImage: section.icon)
                            .font(.headline)
                        sectionContent(for: section)
                            .padding(.leading)
                    }
                    
                    if section != SettingSection.allSections.last {
                        Divider()
                    }
                }
            }
            .padding()
        }
#if os(macOS)
        .frame(minWidth: minWidth, minHeight: minHeight)
#endif
    }
}

private extension SettingView {
    
    // MARK: - Section Content
    @ViewBuilder
    private func sectionContent(for section: SettingSection) -> some View {
        switch section.id {
        case "sync":
            syncSection
        case "notification":
            notificationSection
        case "ai_model":
            aiModelSection
        case "appearance":
            appearanceSection
        case "data":
            dataSection
        case "about":
            aboutSection
        default:
            EmptyView()
        }
    }
    
    // MARK: - Section Views
    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("iCloud Sync", isOn: $enableAutoSync)
#if os(macOS)
                .toggleStyle(.switch)
#endif
            
            if enableAutoSync {
                Text("Last sync time: \(String(describing: lastSyncTime.timeAgoDisplay))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Enable Notifications", isOn: $enableNotification)
#if os(macOS)
                .toggleStyle(.switch)
#endif
            
            if enableNotification {
                Text("After activation, you will receive reading reminders and synchronization completion notifications")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var aiModelSection: some View {
        Button(action: {
            showAIModelList = true
        }) {
            HStack {
                Label("AI Model", systemImage: "brain.head.profile")
                    .foregroundColor(.primary)
                Spacer()
                if let defaultModel = AIModelService.shared.defaultModel {
                    Text(defaultModel.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not Set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
#if os(iOS)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
#endif
            }
        }
#if os(iOS)
        .buttonStyle(.plain)
#else
        .buttonStyle(.plain)
#endif
    }
    
    private var appearanceSection: some View {
        Picker("Theme", selection: $selectedAppearance) {
            ForEach(Appearance.allCases) { appearance in
                Label(appearance.description, systemImage: appearance.icon)
                    .tag(appearance)
            }
        }
#if os(macOS)
        .pickerStyle(.inline)
        .labelsHidden()
#else
        .pickerStyle(.menu)
#endif
    }
    
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(role: .destructive) {
                showClearDataAlert = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
#if os(macOS)
            .buttonStyle(.borderless)
#endif
            .disabled(isClearing)
            
            if isClearing {
                ProgressView("Clearing data...")
                    .progressViewStyle(.circular)
            }
        }
    }
    
    private var aboutSection: some View {
        HStack {
            Text("Version")
            Spacer()
            Text(version)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Alert
    private var clearDataAlert: Alert {
        Alert(
            title: Text("Confirm Data Deletion"),
            message: Text("This action will clear all local data, including:\n• All notes\n• All reminders\n• All app settings\n\nThis action cannot be undone. Continue?"),
            primaryButton: .destructive(Text("Clear")) {
                clearAllData()
            },
            secondaryButton: .cancel(Text("Cancel"))
        )
    }
    
    // MARK: - Actions
    private func clearAllData() {
        isClearing = true
        NotificationManager.shared.removeAllNotifications()
        do {
            try modelContext.delete(model: ReadingCardModel.self)
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error.localizedDescription)")
        }
        
        isClearing = false
        dismiss()
    }
}

#Preview {
    SettingView()
}
