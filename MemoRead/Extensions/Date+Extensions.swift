//
//  Date+Extensions.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .month], from: self, to: now)
        
        if let month = components.month, month > 0 {
            return "\(month) months ago"
        } else if let day = components.day, day > 0 {
            return "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minutes ago"
        } else {
            return "just now"
        }
    }
}
