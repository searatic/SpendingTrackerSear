//
// BudgetSetupView.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Budget management interface
//

import SwiftUI
import SwiftData
import OSLog

struct BudgetSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var categories: [CategoryModel]
    @Query var budgets: [BudgetModel]
    
    var body: some View {
        List {
            Section {
                ForEach(budgets) { budget in
                    if let category = budget.category {
                        BudgetRowView(budget: budget, category: category)
                    }
                }
                .onDelete(perform: deleteBudget)
            } header: {
                Text("Active Budgets")
            }
            
            Section {
                ForEach(availableCategories) { category in
                    Button {
                        addBudget(for: category)
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.name)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            } header: {
                Text("Add Budget")
            }
            
            if categories.isEmpty {
                Section {
                    Text("No categories available. Add an expense to create categories.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Manage Budgets")
        // ← Remove the .sheet modifier that was here
    }
    
    private var availableCategories: [CategoryModel] {
        categories.filter { category in
            !budgets.contains { $0.category?.id == category.id }
        }
    }
    
    private func addBudget(for category: CategoryModel) {
        let budget = BudgetModel(category: category, monthlyLimit: 500.0)
        modelContext.insert(budget)
        
        do {
            try modelContext.save()
        } catch {
            Logger.data.error("Failed to save budget: \(error.localizedDescription)")
        }
    }
    
    private func deleteBudget(at offsets: IndexSet) {
        for index in offsets {
            let budget = budgets[index]
            modelContext.delete(budget)
        }
        
        do {
            try modelContext.save()
        } catch {
            Logger.data.error("Failed to delete budget: \(error.localizedDescription)")
        }
    }
}

struct BudgetRowView: View {
    @Bindable var budget: BudgetModel
    let category: CategoryModel
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(category.color))
                Text(category.name)
                    .font(.headline)
                Spacer()
                Button {
                    isEditing.toggle()
                } label: {
                    Text("Edit")
                        .font(.caption)
                }
            }
            
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Monthly Limit")
                        Spacer()
                        TextField("Amount", value: $budget.monthlyLimit, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Warning at")
                        Spacer()
                        TextField("Percentage", value: $budget.warningThreshold, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("%")
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack {
                    Text("$\(budget.monthlyLimit, specifier: "%.0f")/month")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Warning: \(Int(budget.warningThreshold))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
