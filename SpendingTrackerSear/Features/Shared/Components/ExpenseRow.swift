//
// ExpenseRow.swift
// SpendingTracker/Features/Shared/Components
//
// Created by Developer on 10/5/2025.
// Purpose: Individual expense row display
//

import SwiftUI

struct ExpenseRow: View {
    let expense: ExpenseModel
    
    var body: some View {
        HStack(spacing: 12) {
            if let category = expense.category {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(category.color)
                    .frame(width: 40, height: 40)
                    .background(category.color.opacity(0.2))
                    .clipShape(Circle())
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.location)
                    .font(.headline)
                
                HStack {
                    if let category = expense.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    Image(systemName: expense.paymentMethod.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !expense.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(expense.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(expense.amount, specifier: "%.2f")")
                    .font(.headline)
                
                if expense.receiptPhotoData != nil {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if expense.isPaymentMethodRequired {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    // Create preview container and context
    let container = DataController.preview.container
    let context = container.mainContext
    
    // Create sample category
    let category = CategoryModel(
        name: "Food",
        icon: "fork.knife",
        colorHex: "#FF5733"
    )
    context.insert(category)
    
    // Create sample expense
    let expense = ExpenseModel(
        amount: 45.99,
        category: category,
        location: "Whole Foods",
        date: Date(),
        notes: "Weekly groceries",
        receiptPhotoData: nil,
        isRecurring: false,
        recurringFrequency: nil,
        tags: ["groceries", "essentials"],
        paymentMethod: .credit,
        isPaymentMethodRequired: false
    )
    context.insert(expense)
    
    try? context.save()
    
    // Return the view
    return List {
        ExpenseRow(expense: expense)
        ExpenseRow(expense: expense)
        ExpenseRow(expense: expense)
    }
    .modelContainer(container)
}
