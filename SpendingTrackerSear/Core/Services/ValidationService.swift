//
//  ValidationService.swift
//  SpendingTrackerSear
//
//  Created by Leonard Cratic on 10/5/25.
//

//
// ValidationService.swift
// SpendingTracker/Core/Services
//
// Created by Developer on 10/5/2025.
// Purpose: Input validation utilities
//

import Foundation

struct ValidationService {
    static func isValidAmount(_ amount: String) -> Bool {
        guard let value = Double(amount), value > 0 else {
            return false
        }
        return true
    }
    
    static func isValidLocation(_ location: String) -> Bool {
        return !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
