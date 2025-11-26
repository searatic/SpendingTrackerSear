//
// CategoryBudgetView.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Category-specific budget details
//

import SwiftUI
import SwiftData

struct CategoryBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    let categoryId: UUID  // ← Changed from CategoryModel to UUID
    
    @Query private var allExpenses: [ExpenseModel]
    @Query private var allBudgets: [BudgetModel]
    @Query private var allCategories: [CategoryModel]  // ← Add this
    
    private var category: CategoryModel? {  // ← Add this computed property
        allCategories.first { $0.id == categoryId }
    }
    
    private var categoryExpenses: [ExpenseModel] {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        return allExpenses.filter { expense in
            expense.category?.id == categoryId && expense.date >= startOfMonth
        }
    }
    
    private var budget: BudgetModel? {
        allBudgets.first { $0.category?.id == categoryId }
    }
    
    private var totalSpent: Double {
        categoryExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        Group {
            if let category = category {
                List {
                    if let budget = budget {
                        Section {
                            BudgetStatusCard(budget: budget, currentSpending: totalSpent)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }
                    
                    Section("This Month's Expenses") {
                        ForEach(categoryExpenses.sorted { $0.date > $1.date }) { expense in
                            ExpenseRow(expense: expense)
                        }
                    }
                }
                .navigationTitle(category.name)
            } else {
                ContentUnavailableView("Category Not Found", systemImage: "exclamationmark.triangle")
            }
        }
    }
}
