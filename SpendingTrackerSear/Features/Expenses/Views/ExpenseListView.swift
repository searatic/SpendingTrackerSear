//
// ExpenseListView.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Main expense list with budget warnings
//

import SwiftUI
import SwiftData
import OSLog

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @State private var viewModel = ExpenseListViewModel()
    
    @Query(sort: \ExpenseModel.date, order: .reverse) private var allExpenses: [ExpenseModel]
    @Query var categories: [CategoryModel]
    @Query var budgets: [BudgetModel]
    
    var filteredExpenses: [ExpenseModel] {
        var expenses = allExpenses
        
        // Search filter
        if !viewModel.searchText.isEmpty {
            expenses = expenses.filter { expense in
                expense.location.localizedCaseInsensitiveContains(viewModel.searchText) ||
                expense.notes.localizedCaseInsensitiveContains(viewModel.searchText) ||
                expense.category?.name.localizedCaseInsensitiveContains(viewModel.searchText) ?? false
            }
        }
        
        // Category filter
        if let selectedCategory = viewModel.selectedCategory {
            expenses = expenses.filter { $0.category?.id == selectedCategory.id }
        }
        
        // Date filter
        expenses = expenses.filter { viewModel.dateFilter.predicate()($0.date) }
        
        // Sort
        switch viewModel.sortOption {
        case .dateDescending:
            expenses.sort { $0.date > $1.date }
        case .dateAscending:
            expenses.sort { $0.date < $1.date }
        case .amountDescending:
            expenses.sort { $0.amount > $1.amount }
        case .amountAscending:
            expenses.sort { $0.amount < $1.amount }
        }
        
        return expenses
    }
    
    var totalSpending: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Budget Status Cards
            if !budgets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(budgets) { budget in
                            if let category = budget.category {
                                BudgetStatusCard(
                                    budget: budget,
                                    currentSpending: getCurrentMonthSpending(for: category)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
                .background(Color(.systemGroupedBackground))
            }
            
            // Expense List
            List {
                Section {
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(totalSpending, specifier: "%.2f")")
                            .font(.title2)
                            .bold()
                    }
                }
                
                ForEach(filteredExpenses) { expense in
                    ExpenseRow(expense: expense)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            router.navigate(to: .expenseDetail(id: expense.id))
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let expense = filteredExpenses[index]
                        Task {
                            await viewModel.deleteExpense(expense)
                        }
                    }
                }
            }
        }
        .navigationTitle("Spending Tracker")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        router.navigate(to: .addExpense)
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                    
                    // ✅ FIXED: Navigate to addExpense instead of scanReceipt
                    // User can then tap "Scan Receipt" button inside AddExpenseView
                    Button {
                        router.navigate(to: .addExpense)
                    } label: {
                        Label("Scan Receipt", systemImage: "camera")
                    }
                    
                    Divider()
                    
                    Button {
                        router.navigate(to: .budgetSetup)
                    } label: {
                        Label("Manage Budgets", systemImage: "chart.bar")
                    }
                    
                    Button {
                        router.navigate(to: .charts)
                    } label: {
                        Label("View Charts", systemImage: "chart.pie")
                    }
                    
                    Divider()
                    
                    Button {
                        Task {
                            await viewModel.exportToCSV()
                        }
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search expenses")
        .sheet(isPresented: $viewModel.showingExportSheet) {
            if let url = viewModel.exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            viewModel.configure(with: ExpenseService(modelContext: modelContext))
        }
    }
    
    private func getCurrentMonthSpending(for category: CategoryModel) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        return allExpenses
            .filter { $0.category?.id == category.id && $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.amount }
    }
}
