//
// BudgetModel.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Budget tracking model
//

import SwiftData
import Foundation
import SwiftUI

@Model
final class BudgetModel {
    @Attribute(.unique) var id: UUID
    var category: CategoryModel?
    var monthlyLimit: Double
    var warningThreshold: Double // Percentage (e.g., 80 for 80%)
    var createdAt: Date
    
    init(category: CategoryModel?, monthlyLimit: Double, warningThreshold: Double = 80.0) {
        self.id = UUID()
        self.category = category
        self.monthlyLimit = monthlyLimit
        self.warningThreshold = warningThreshold
        self.createdAt = Date()
    }
    
    func budgetStatus(currentSpending: Double) -> BudgetStatus {
        let percentage = (currentSpending / monthlyLimit) * 100
        
        if percentage >= 100 {
            return .over
        } else if percentage >= warningThreshold {
            return .warning
        } else {
            return .safe
        }
    }
    
    // Calculate remaining budget
    func remainingBudget(currentSpending: Double) -> Double {
        return max(0, monthlyLimit - currentSpending)
    }
    
    // Calculate percentage used
    func percentageUsed(currentSpending: Double) -> Double {
        return min(100, (currentSpending / monthlyLimit) * 100)
    }
}

enum BudgetStatus {
    case safe
    case warning
    case over
    
    // SwiftUI Color for UI components
    var color: Color {
        switch self {
        case .safe: return .green
        case .warning: return .orange
        case .over: return .red
        }
    }
    
    // String color name for backwards compatibility
    var colorName: String {
        switch self {
        case .safe: return "green"
        case .warning: return "yellow"
        case .over: return "red"
        }
    }
    
    var message: String {
        switch self {
        case .safe: return "On track"
        case .warning: return "Approaching limit"
        case .over: return "Over budget"
        }
    }
    
    var icon: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .over: return "xmark.circle.fill"
        }
    }
}
