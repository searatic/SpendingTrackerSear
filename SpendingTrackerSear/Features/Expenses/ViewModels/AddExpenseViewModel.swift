//
// AddExpenseViewModel.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: ViewModel for adding/editing expenses with receipt scanning support
//

import SwiftUI
import SwiftData
import OSLog

@MainActor
@Observable
class AddExpenseViewModel {
    var amount: String = ""
    var category: CategoryModel?
    var paymentMethod: PaymentMethod = .cash
    var location: String = ""
    var notes: String = ""
    var tags: String = ""
    var selectedDate: Date = Date()
    var isRecurring: Bool = false
    var recurringFrequency: RecurringFrequency = .monthly
    var paymentMethodRequired: Bool = false
    var hasPhoto: Bool = false
    var photoData: Data?
    
    var showingScanner: Bool = false
    var showingCamera: Bool = false
    var errorMessage: String?
    var isLoading: Bool = false
    
    // State management for scanned data
    var pendingScanData: ReceiptData?
    var shouldProcessScan: Bool = false
    
    private let modelContext: ModelContext
    private var expenseService: ExpenseService?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func configure(with expenseService: ExpenseService) {
        self.expenseService = expenseService
    }
    
    func validateInput() -> Bool {
        guard !amount.isEmpty,
              Double(amount) != nil,
              !location.isEmpty else {
            return false
        }
        return true
    }
    
    func saveExpense() async {
        guard let expenseService = expenseService else {
            errorMessage = "Service not configured"
            return
        }
        
        guard validateInput() else {
            errorMessage = "Please fill in amount and location"
            return
        }
        
        guard let amountValue = Double(amount) else {
            errorMessage = "Invalid amount"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            _ = try await expenseService.createExpense(
                amount: amountValue,
                category: category,
                location: location,
                date: selectedDate,
                notes: notes,
                receiptPhotoData: photoData,
                isRecurring: isRecurring,
                recurringFrequency: isRecurring ? recurringFrequency : nil,
                tags: tagArray,
                paymentMethod: paymentMethod,
                isPaymentMethodRequired: paymentMethodRequired
            )
            
            Logger.data.info("Expense saved successfully")
            
            // Reset form
            resetForm()
            
        } catch let error as AppError {
            errorMessage = error.errorDescription
            Logger.data.error("Failed to save expense: \(error.errorDescription ?? "Unknown error")")
        } catch {
            errorMessage = "An unexpected error occurred"
            Logger.data.error("Unexpected error saving expense: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // Process scanned receipt data via state
    func processPendingScan() {
        guard let scanData = pendingScanData else { return }
        
        Logger.data.info("🟢 Processing scanned receipt in ViewModel")
        
        if let amountValue = scanData.amount {
            amount = String(format: "%.2f", amountValue)
            Logger.data.info("✅ Amount set to: \(self.amount)")
        }
        
        if let locationValue = scanData.location, !locationValue.isEmpty {
            location = locationValue
            Logger.data.info("✅ Location set to: \(self.location)")
        }
        
        if let dateValue = scanData.date {
            selectedDate = dateValue
            Logger.data.info("✅ Date set to: \(dateValue)")
        }
        
        // Clear pending data
        pendingScanData = nil
        shouldProcessScan = false
        
        Logger.data.info("✅ Receipt processing complete")
    }
    
    // DEPRECATED: Keep for backwards compatibility but not used
    func processScannedReceipt(_ receiptData: ReceiptData) {
        Logger.data.info("⚠️ Legacy processScannedReceipt called - use state-based approach instead")
        pendingScanData = receiptData
        shouldProcessScan = true
    }
    
    func resetForm() {
        amount = ""
        category = nil
        paymentMethod = .cash
        location = ""
        notes = ""
        tags = ""
        selectedDate = Date()
        isRecurring = false
        recurringFrequency = .monthly
        paymentMethodRequired = false
        hasPhoto = false
        photoData = nil
        pendingScanData = nil
        shouldProcessScan = false
    }
}
