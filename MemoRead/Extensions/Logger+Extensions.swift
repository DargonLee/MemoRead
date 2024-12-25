//
//  Logger+Extensions.swift
//  MemoRead
//
//  Created by Harlans on 2024/12/25.
//

import OSLog

extension Logger {
    private static let appIdentifier = Bundle.main.bundleIdentifier ?? ""
    static let main = Logger(subsystem: appIdentifier, category: "main")
    static func previewInfo(_ message: String) {
        print("\(message)")
    }
}
