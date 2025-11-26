//
// CategoryModel.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: Category model for expense categorization
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CategoryModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var budgetLimit: Double?
    var isDefault: Bool
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \ExpenseModel.category)
    var expenses: [ExpenseModel]?
    
    init(
        name: String,
        icon: String,
        colorHex: String,
        budgetLimit: Double? = nil,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.budgetLimit = budgetLimit
        self.isDefault = isDefault
        self.createdAt = Date()
    }
    
    // Computed property to convert hex string to Color
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // Default categories for first-time setup
    static var defaultCategories: [CategoryModel] {
        [
            CategoryModel(
                name: "Food & Dining",
                icon: "fork.knife",
                colorHex: "#FF6B6B",
                isDefault: true
            ),
            CategoryModel(
                name: "Groceries",
                icon: "cart.fill",
                colorHex: "#4ECDC4",
                isDefault: true
            ),
            CategoryModel(
                name: "Transportation",
                icon: "car.fill",
                colorHex: "#45B7D1",
                isDefault: true
            ),
            CategoryModel(
                name: "Shopping",
                icon: "bag.fill",
                colorHex: "#FFA07A",
                isDefault: true
            ),
            CategoryModel(
                name: "Entertainment",
                icon: "theatermasks.fill",
                colorHex: "#98D8C8",
                isDefault: true
            ),
            CategoryModel(
                name: "Bills & Utilities",
                icon: "bolt.fill",
                colorHex: "#F7DC6F",
                isDefault: true
            ),
            CategoryModel(
                name: "Healthcare",
                icon: "cross.fill",
                colorHex: "#BB8FCE",
                isDefault: true
            ),
            CategoryModel(
                name: "Personal Care",
                icon: "scissors",
                colorHex: "#F8B4D9",
                isDefault: true
            ),
            CategoryModel(
                name: "Education",
                icon: "book.fill",
                colorHex: "#85C1E2",
                isDefault: true
            ),
            CategoryModel(
                name: "Travel",
                icon: "airplane",
                colorHex: "#52B788",
                isDefault: true
            ),
            CategoryModel(
                name: "Housing",
                icon: "house.fill",
                colorHex: "#DDA15E",
                isDefault: true
            ),
            CategoryModel(
                name: "Insurance",
                icon: "shield.fill",
                colorHex: "#BC6C25",
                isDefault: true
            ),
            CategoryModel(
                name: "Gifts & Donations",
                icon: "gift.fill",
                colorHex: "#E07A5F",
                isDefault: true
            ),
            CategoryModel(
                name: "Fitness",
                icon: "figure.run",
                colorHex: "#81B29A",
                isDefault: true
            ),
            CategoryModel(
                name: "Subscriptions",
                icon: "arrow.clockwise.circle.fill",
                colorHex: "#6C757D",
                isDefault: true
            ),
            CategoryModel(
                name: "Other",
                icon: "ellipsis.circle.fill",
                colorHex: "#95A5A6",
                isDefault: true
            )
        ]
    }
}

// Extension to create Color from hex string
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    // Convert Color to hex string
    var hexString: String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}
