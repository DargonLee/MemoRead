//
//  NotificationManager.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // 请求通知权限
        requestAuthorization()
    }
    
    // MARK: - Authorization
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限获取成功")
            } else if let error = error {
                print("通知权限获取失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func scheduleNotification(for card: ReadingCardModel) {
        // 检查是否有提醒时间
        guard let reminderAt = card.reminderAt else { return }
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "阅读提醒"
        content.body = card.content.prefix(100) + (card.content.count > 100 ? "..." : "")
        content.sound = .default
        
        // 创建触发器
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: card.id.uuidString,  // 使用卡片ID作为通知标识符
            content: content,
            trigger: trigger
        )
        
        // 添加通知请求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败: \(error.localizedDescription)")
            } else {
                print("成功添加通知，将在 \(reminderAt) 提醒")
            }
        }
    }
    
    // MARK: - Utility Methods
    func removeNotification(for cardId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [cardId.uuidString]
        )
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
}
