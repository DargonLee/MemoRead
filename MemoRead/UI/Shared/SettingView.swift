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
    @AppStorage("enableAutoSync") private var enableAutoSync = true
    @AppStorage("enableNotification") private var enableNotification = true
    @AppStorage("enableDarkMode") private var enableDarkMode = false
    @State private var showClearDataAlert = false
    @State private var selectedAppearance: Appearance = .automatic
    @AppStorage("lastSyncTime") private var lastSyncTime = Date()
    
    var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
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
                        Text("After activation, you will receive reading reminders and synchronization completion notifications")
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
            .alert("Confirm to Clear Data", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                        // TODO: 清除数据的逻辑
                }
            } message: {
                Text("This operation will clear all local data and it cannot be recovered. Do you want to continue?")
            }
        }
    }
}

#Preview {
    SettingView()
}
