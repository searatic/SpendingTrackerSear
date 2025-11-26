//
// DataController.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Centralized SwiftData persistence management
//

import SwiftData
import SwiftUI
import OSLog

@MainActor
class DataController {
    static let shared = DataController()
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            ExpenseModel.self,
            CategoryModel.self,
            BudgetModel.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
            Logger.data.info("✅ ModelContainer created successfully")
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // Preview configuration for SwiftUI previews
    static let preview: DataController = {
        let controller = DataController()
        let context = controller.container.mainContext
        
        // Add preview categories
        let groceryCategory = CategoryModel(
            name: "Groceries",
            icon: "cart.fill",
            colorHex: "#4ECDC4"
        )
        context.insert(groceryCategory)
        
        let foodCategory = CategoryModel(
            name: "Food & Dining",
            icon: "fork.knife",
            colorHex: "#FF6B6B"
        )
        context.insert(foodCategory)
        
        // Add preview expenses with CORRECT parameter order
        let expense1 = ExpenseModel(
            amount: 45.99,                          // 1. amount
            category: groceryCategory,              // 2. category
            location: "Whole Foods",                // 3. location
            date: Date(),                           // 4. date
            notes: "Weekly shopping",               // 5. notes
            receiptPhotoData: nil,                  // 6. receiptPhotoData
            isRecurring: false,                     // 7. isRecurring
            recurringFrequency: nil,                // 8. recurringFrequency
            tags: ["groceries", "essentials"],      // 9. tags
            paymentMethod: .credit,                 // 10. paymentMethod
            isPaymentMethodRequired: false          // 11. isPaymentMethodRequired
        )
        context.insert(expense1)
        
        let expense2 = ExpenseModel(
            amount: 23.50,
            category: foodCategory,
            location: "Local Cafe",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            notes: "Lunch meeting",
            receiptPhotoData: nil,
            isRecurring: false,
            recurringFrequency: nil,
            tags: ["dining", "business"],
            paymentMethod: .cash,
            isPaymentMethodRequired: false
        )
        context.insert(expense2)
        
        // Add preview budget
        let budget = BudgetModel(
            category: groceryCategory,
            monthlyLimit: 500.0
        )
        context.insert(budget)
        
        try? context.save()
        Logger.data.info("✅ Preview data created")
        return controller
    }()
}
