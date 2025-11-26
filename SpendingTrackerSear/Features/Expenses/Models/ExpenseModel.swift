//
// ExpenseModel.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: Expense model for tracking spending
//

import Foundation
import SwiftData

@Model
final class ExpenseModel {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var category: CategoryModel?
    var paymentMethod: PaymentMethod
    var location: String
    var notes: String
    var tags: [String]
    var date: Date
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    var isPaymentMethodRequired: Bool
    var receiptPhotoData: Data?
    var createdAt: Date
    
    init(
        amount: Double,
        category: CategoryModel?,
        location: String,
        date: Date,
        notes: String = "",
        receiptPhotoData: Data? = nil,
        isRecurring: Bool = false,
        recurringFrequency: RecurringFrequency? = nil,
        tags: [String] = [],
        paymentMethod: PaymentMethod = .cash,
        isPaymentMethodRequired: Bool = false
    ) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.paymentMethod = paymentMethod
        self.location = location
        self.notes = notes
        self.tags = tags
        self.date = date
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.isPaymentMethodRequired = isPaymentMethodRequired
        self.receiptPhotoData = receiptPhotoData
        self.createdAt = Date()
    }
}

// Payment Method Enum
enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case credit = "Credit Card"
    case debit = "Debit Card"
    case bankTransfer = "Bank Transfer"
    case digitalWallet = "Digital Wallet"
    
    var icon: String {
        switch self {
        case .cash:
            return "dollarsign.circle.fill"
        case .credit:
            return "creditcard.fill"
        case .debit:
            return "banknote.fill"
        case .bankTransfer:
            return "building.columns.fill"
        case .digitalWallet:
            return "wallet.pass.fill"
        }
    }
}

// Recurring Frequency Enum
enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}
