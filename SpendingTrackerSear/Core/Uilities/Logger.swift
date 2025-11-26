//
//  Logger.swift
//  SpendingTrackerSear
//
//  Created by Leonard Cratic on 10/5/25.
//

//
// Logger.swift
// SpendingTracker/Core/Utilities
//
// Created by Developer on 10/5/2025.
// Purpose: Centralized logging
//

import OSLog

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "general")
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "data")
}
