//
// Router.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Centralized navigation management
//

import SwiftUI

@Observable
class Router {
    var path = NavigationPath()
    
    func navigate(to destination: Route) {
        path.append(destination)
    }
    
    func navigateBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
    
    func replace(with destination: Route) {
        path.removeLast(path.count)
        path.append(destination)
    }
}

enum Route: Hashable {
    case expenseList
    case addExpense
    case addExpenseWithScan(receiptData: ReceiptData)
    case budgetSetup
    case charts
    case expenseDetail(id: UUID)
    case categoryBudget(categoryId: UUID)

    @ViewBuilder
    var destination: some View {
        switch self {
        case .expenseList:
            ExpenseListView()
        case .addExpense:
            AddExpenseView()
        case .addExpenseWithScan(let receiptData):
            AddExpenseView(initialReceiptData: receiptData)
        case .budgetSetup:
            BudgetSetupView()
        case .charts:
            ChartsView()
        case .expenseDetail(let id):
            ExpenseDetailView(expenseId: id)
        case .categoryBudget(let categoryId):
            CategoryBudgetView(categoryId: categoryId)
        }
    }
}
