//
//  SettingView.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/26.
//

import SwiftUI

struct SettingView: View {
    // MARK: - State
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("enableAutoSync") private var enableAutoSync = true
    @AppStorage("enableNotification") private var enableNotification = true
    @AppStorage("enableDarkMode") private var enableDarkMode = false
    @State private var showClearDataAlert = false
    @State private var selectedAppearance: Appearance = .automatic
    @AppStorage("lastSyncTime") private var lastSyncTime = Date()
    @State private var isClearing = false
    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
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
    
    // MARK: - Alert Content
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sync") {
                    Toggle("iCloud Sync", isOn: $enableAutoSync)
                    if enableAutoSync {
                        Text("Last sync time: \(String(describing: lastSyncTime.timeAgoDisplay))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Notification") {
                    Toggle("Notification", isOn: $enableNotification)
                    if enableNotification {
                        Text(
                            "After activation, you will receive reading reminders and synchronization completion notifications"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                
                Section("Appearance") {
                    Picker("Appearance Mode", selection: $selectedAppearance) {
                        ForEach(Appearance.allCases) { appearance in
                            Label(appearance.description, systemImage: appearance.icon)
                                .tag(appearance)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Data Management") {
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                    .disabled(isClearing)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(version)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Setting")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
#endif
            .alert(isPresented: $showClearDataAlert) {
                clearDataAlert
            }
            .overlay {
                if isClearing {
                    ProgressView("Clearing data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
}

#Preview {
    SettingView()
}
