//
//  AppError.swift
//  SpendingTrackerSear
//
//  Created by Leonard Cratic on 10/5/25.
//

//
// AppError.swift
// SpendingTracker/Core/Utilities
//
// Created by Developer on 10/5/2025.
// Purpose: Standardized error handling
//

import Foundation

enum AppError: LocalizedError {
    case validationFailed(String)
    case dataNotFound
    case invalidInput
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .dataNotFound:
            return "The requested data could not be found."
        case .invalidInput:
            return "Invalid input provided."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
