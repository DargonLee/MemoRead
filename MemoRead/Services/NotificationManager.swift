//
//  NotificationManager.swift
//  MemoRead
//
//  Created by Harlans on 2025/1/15.
//

import Foundation
import UserNotifications
import SwiftData

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        // 请求通知权限
        requestAuthorization()
    }
    
    // MARK: - Authorization
    /// 检查通知权限状态
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
    
    /// 请求通知权限
    func requestAuthorization(completion: ((Bool, Error?) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("通知权限获取成功")
            } else if let error = error {
                print("通知权限获取失败: \(error.localizedDescription)")
            }
            completion?(granted, error)
        }
    }
    
    /// 确保有通知权限，如果没有则请求
    func ensureAuthorization(completion: @escaping (Bool) -> Void) {
        checkAuthorizationStatus { status in
            switch status {
            case .authorized, .provisional:
                // 已有权限
                completion(true)
            case .notDetermined:
                // 未确定，请求权限
                self.requestAuthorization { granted, _ in
                    completion(granted)
                }
            case .denied, .ephemeral:
                // 已拒绝或临时权限
                print("通知权限已被拒绝，无法发送通知")
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }
    
    // MARK: - Notification Management
    func scheduleNotification(for card: ReadingCardModel) {
        // 检查是否有提醒时间
        guard let reminderAt = card.reminderAt else { return }
        
        // 确保有权限后再安排通知
        ensureAuthorization { [weak self] authorized in
            guard authorized, let self = self else {
                print("通知权限未授权，无法安排提醒通知")
                return
            }
            
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
    
    // MARK: - Instant Notifications
    /// 发送即时通知（用于同步完成等场景）
    /// 会自动检查并请求权限（如果需要）
    func sendInstantNotification(title: String, body: String, sound: Bool = true) {
        ensureAuthorization { authorized in
            guard authorized else {
                print("通知权限未授权，无法发送通知")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            if sound {
                content.sound = .default
            }
            
            // 立即触发（延迟 0.1 秒以确保通知系统准备就绪）
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("发送即时通知失败: \(error.localizedDescription)")
                } else {
                    print("成功发送即时通知: \(title)")
                }
            }
        }
    }
}
