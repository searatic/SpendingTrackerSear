//
// ExpenseDetailView.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Detailed expense view and editing
//

import SwiftUI
import SwiftData
import OSLog

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let expenseId: UUID
    
    @Query private var allExpenses: [ExpenseModel]
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    private var expense: ExpenseModel? {
        allExpenses.first { $0.id == expenseId }
    }
    
    var body: some View {
        Group {
            if let expense = expense {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Amount
                        VStack(alignment: .center, spacing: 8) {
                            Text("$\(expense.amount, specifier: "%.2f")")
                                .font(.system(size: 48, weight: .bold))
                            
                            if let category = expense.category {
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.name)
                                }
                                .font(.headline)
                                .foregroundStyle(Color(category.color))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        
                        Divider()
                        
                        // Details
                        DetailRow(icon: "location.fill", title: "Location", value: expense.location)
                        DetailRow(icon: "calendar", title: "Date", value: expense.date.formatted(date: .long, time: .omitted))
                        
                        // Payment Method with Required Indicator
                        HStack {
                            Image(systemName: expense.paymentMethod.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            Text("Payment")
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(expense.paymentMethod.rawValue)
                                    .foregroundStyle(.secondary)
                                if expense.isPaymentMethodRequired {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                        Text("Required")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(.orange)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if !expense.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(.secondary)
                                    Text("Notes")
                                        .font(.headline)
                                }
                                Text(expense.notes)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !expense.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundStyle(.secondary)
                                    Text("Tags")
                                        .font(.headline)
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(expense.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if expense.isRecurring, let frequency = expense.recurringFrequency {
                            DetailRow(icon: "repeat", title: "Recurring", value: frequency.rawValue)
                        }
                        
                        // Receipt Photo
                        if let photoData = expense.receiptPhotoData,
                           let image = UIImage(data: photoData) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "paperclip")
                                        .foregroundStyle(.secondary)
                                    Text("Receipt")
                                        .font(.headline)
                                }
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Created: \(expense.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Expense Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .alert("Delete Expense", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        deleteExpense(expense)
                    }
                } message: {
                    Text("Are you sure you want to delete this expense?")
                }
            } else {
                ContentUnavailableView("Expense Not Found", systemImage: "exclamationmark.triangle")
            }
        }
    }
    
    private func deleteExpense(_ expense: ExpenseModel) {
        modelContext.delete(expense)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            Logger.data.error("Failed to delete expense: \(error.localizedDescription)")
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}
