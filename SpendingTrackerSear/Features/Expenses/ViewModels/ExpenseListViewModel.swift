//
// ExpenseListViewModel.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Expense list display and filtering logic
//

import SwiftUI
import SwiftData
import OSLog

@MainActor
@Observable
class ExpenseListViewModel {
    var searchText: String = ""
    var selectedCategory: CategoryModel?
    var dateFilter: DateFilter = .all
    var sortOption: SortOption = .dateDescending
    var showingExportSheet: Bool = false
    var exportURL: URL?
    var errorMessage: String?
    
    private var expenseService: ExpenseService?
    
    func configure(with expenseService: ExpenseService) {
        self.expenseService = expenseService
    }
    
    func exportToCSV() async {
        guard let expenseService = expenseService else { return }
        
        do {
            exportURL = try expenseService.exportToCSV()
            showingExportSheet = true
        } catch {
            errorMessage = "Failed to export expenses"
            Logger.app.error("Export error: \(error.localizedDescription)")
        }
    }
    
    func deleteExpense(_ expense: ExpenseModel) async {
        guard let expenseService = expenseService else { return }
        
        do {
            try await expenseService.deleteExpense(expense)
        } catch {
            errorMessage = "Failed to delete expense"
            Logger.app.error("Delete error: \(error.localizedDescription)")
        }
    }
}

enum DateFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    
    func predicate() -> (Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return { _ in true }
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            return { $0 >= startOfDay }
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return { $0 >= startOfWeek }
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return { $0 >= startOfMonth }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return { $0 >= startOfYear }
        }
    }
}

enum SortOption: String, CaseIterable {
    case dateDescending = "Newest First"
    case dateAscending = "Oldest First"
    case amountDescending = "Highest Amount"
    case amountAscending = "Lowest Amount"
}
