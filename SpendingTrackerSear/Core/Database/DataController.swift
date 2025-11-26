//
//  DataController.swift
//  SpendingTrackerSear
//
//  Centralized SwiftData persistence management
//

import SwiftData
import SwiftUI
import OSLog

final class DataController {
    let container: ModelContainer

    // MARK: - Initializers

    /// Main app initializer (persistent on disk)
    private init(inMemory: Bool = false) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)

            container = try ModelContainer(
                for: ExpenseModel.self,
                CategoryModel.self,
                BudgetModel.self,
                configurations: configuration
            )

            Logger.data.info("✅ ModelContainer created successfully (inMemory: \(inMemory, privacy: .public))")
        } catch {
            Logger.data.fault("❌ Failed to create ModelContainer: \(String(describing: error), privacy: .public)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Shared instances

    /// Live container for the running app
    @MainActor
    static let live: DataController = {
        DataController(inMemory: false)
    }()

    /// In-memory container for SwiftUI previews
    @MainActor
    static let preview: DataController = {
        let controller = DataController(inMemory: true)
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

        // Add preview expenses
        let expense1 = ExpenseModel(
            amount: 45.99,
            category: groceryCategory,
            location: "Whole Foods",
            date: Date(),
            notes: "Weekly shopping",
            receiptPhotoData: nil,
            isRecurring: false,
            recurringFrequency: nil,
            tags: ["groceries", "essentials"],
            paymentMethod: .credit,
            isPaymentMethodRequired: false
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

        do {
            try context.save()
            Logger.data.info("✅ Preview data created")
        } catch {
            Logger.data.error("❌ Failed to save preview data: \(String(describing: error), privacy: .public)")
        }

        return controller
    }()
}
