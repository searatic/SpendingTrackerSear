//
// ExpenseService.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Expense business logic and data operations
//

import SwiftData
import Foundation
import OSLog

@MainActor
class ExpenseService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createExpense(
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
        isPaymentMethodRequired: Bool = false  // ← Add this
    ) async throws -> ExpenseModel {
        
        guard amount > 0 else {
            throw AppError.validationFailed("Amount must be greater than zero")
        }
        
        guard !location.isEmpty else {
            throw AppError.validationFailed("Location is required")
        }
        
        let expense = ExpenseModel(
            amount: amount,
            category: category,
            location: location,
            date: date,
            notes: notes,
            receiptPhotoData: receiptPhotoData,
            isRecurring: isRecurring,
            recurringFrequency: recurringFrequency,
            tags: tags,
            paymentMethod: paymentMethod,
            isPaymentMethodRequired: isPaymentMethodRequired  // ← Add this
        )
        
        modelContext.insert(expense)
        
        do {
            try modelContext.save()
            Logger.data.info("Expense created successfully: \(expense.id)")
            return expense
        } catch {
            Logger.data.error("Failed to save expense: \(error.localizedDescription)")
            modelContext.delete(expense)
            throw AppError.unknown(error)
        }
    }

    func updateExpense(
        _ expense: ExpenseModel,
        amount: Double,
        category: CategoryModel?,
        location: String,
        date: Date,
        notes: String,
        receiptPhotoData: Data?,
        tags: [String],
        paymentMethod: PaymentMethod,
        isPaymentMethodRequired: Bool  // ← Add this
    ) async throws {
        
        expense.amount = amount
        expense.category = category
        expense.location = location
        expense.date = date
        expense.notes = notes
        expense.receiptPhotoData = receiptPhotoData
        expense.tags = tags
        expense.paymentMethod = paymentMethod
        expense.isPaymentMethodRequired = isPaymentMethodRequired  // ← Add this
        
        do {
            try modelContext.save()
            Logger.data.info("Expense updated successfully")
        } catch {
            Logger.data.error("Failed to update expense: \(error.localizedDescription)")
            throw AppError.unknown(error)
        }
    }
    
    func deleteExpense(_ expense: ExpenseModel) async throws {
        modelContext.delete(expense)
        
        do {
            try modelContext.save()
            Logger.data.info("Expense deleted successfully")
        } catch {
            Logger.data.error("Failed to delete expense: \(error.localizedDescription)")
            throw AppError.unknown(error)
        }
    }
    
    func getMonthlySpending(for category: CategoryModel?, month: Date) -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.year, .month], from: month))!)
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let descriptor = FetchDescriptor<ExpenseModel>(
            predicate: #Predicate { expense in
                expense.date >= startOfMonth && expense.date <= endOfMonth
            }
        )
        
        let expenses = (try? modelContext.fetch(descriptor)) ?? []
        
        if let category = category {
            return expenses.filter { $0.category?.id == category.id }.reduce(0) { $0 + $1.amount }
        } else {
            return expenses.reduce(0) { $0 + $1.amount }
        }
    }
    
    func exportToCSV() throws -> URL {
        let descriptor = FetchDescriptor<ExpenseModel>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let expenses = try modelContext.fetch(descriptor)
        
        var csvString = "Date,Category,Location,Amount,Payment Method,Notes,Tags\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for expense in expenses {
            let dateString = dateFormatter.string(from: expense.date)
            let category = expense.category?.name ?? "Uncategorized"
            let tags = expense.tags.joined(separator: "; ")
            
            csvString += "\"\(dateString)\",\"\(category)\",\"\(expense.location)\",\"\(expense.amount)\",\"\(expense.paymentMethod.rawValue)\",\"\(expense.notes)\",\"\(tags)\"\n"
        }
        
        let fileName = "expenses_export_\(Date().timeIntervalSince1970).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        Logger.data.info("CSV export created: \(fileName)")
        
        return fileURL
    }
}
