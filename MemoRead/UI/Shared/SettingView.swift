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

    var body: some View {
        NavigationStack {
            Form {
                // 同步设置
                Section("同步") {
                    Toggle("iCloud 同步", isOn: $enableAutoSync)
                    if enableAutoSync {
                        Text("上次同步时间: 3天前")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // 通知设置
                Section("通知") {
                    Toggle("推送通知", isOn: $enableNotification)
                    if enableNotification {
                        Text("开启后将接收阅读提醒和同步完成通知")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // 外观设置
                Section("外观") {
                    Picker("外观模式", selection: $selectedAppearance) {
                        ForEach(Appearance.allCases) { appearance in
                            Label(appearance.description, systemImage: appearance.icon)
                                .tag(appearance)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 数据管理
                Section("数据管理") {
                    Button(role: .destructive) {
                        showClearDataAlert = true
                    } label: {
                        Label("清除所有数据", systemImage: "trash")
                    }
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("确认清除数据", isPresented: $showClearDataAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    // TODO: 清除数据的逻辑
                }
            } message: {
                Text("此操作将清除所有本地数据且无法恢复，是否继续？")
            }
        }
    }
}

#Preview {
    SettingView()
}
