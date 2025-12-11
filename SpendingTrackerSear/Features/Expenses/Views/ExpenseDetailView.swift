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
    @Query private var allCategories: [CategoryModel]
    @State private var isEditing = false
    @State private var showingDeleteAlert = false

    // Edit mode state
    @State private var editAmount: String = ""
    @State private var editLocation: String = ""
    @State private var editCategory: CategoryModel?
    @State private var editPaymentMethod: PaymentMethod = .cash
    @State private var editDate: Date = Date()
    @State private var editTags: String = ""
    @State private var editNotes: String = ""

    // Original values for cancel
    private struct OriginalValues {
        var amount: Double
        var location: String
        var category: CategoryModel?
        var paymentMethod: PaymentMethod
        var date: Date
        var tags: [String]
        var notes: String
    }
    @State private var originalValues: OriginalValues?

    private var expense: ExpenseModel? {
        allExpenses.first { $0.id == expenseId }
    }
    
    var body: some View {
        Group {
            if let expense = expense {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if isEditing {
                            editModeContent(expense: expense)
                        } else {
                            viewModeContent(expense: expense)
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle(isEditing ? "Edit Expense" : "Expense Details")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(isEditing)
                .toolbar {
                    if isEditing {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                cancelEditing()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveChanges(expense: expense)
                            }
                        }
                    } else {
                        ToolbarItem(placement: .primaryAction) {
                            HStack {
                                Button("Edit") {
                                    startEditing(expense: expense)
                                }
                                Button {
                                    showingDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
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

    // MARK: - View Mode Content
    @ViewBuilder
    private func viewModeContent(expense: ExpenseModel) -> some View {
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

    // MARK: - Edit Mode Content
    @ViewBuilder
    private func editModeContent(expense: ExpenseModel) -> some View {
        VStack(spacing: 16) {
            // Amount
            VStack(alignment: .leading, spacing: 4) {
                Text("Amount")
                    .font(.headline)
                HStack {
                    Text("$")
                        .font(.title2)
                    TextField("0.00", text: $editAmount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // Location
            VStack(alignment: .leading, spacing: 4) {
                Text("Location")
                    .font(.headline)
                TextField("Enter location", text: $editLocation)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Category
            VStack(alignment: .leading, spacing: 4) {
                Text("Category")
                    .font(.headline)
                Picker("Category", selection: $editCategory) {
                    Text("None").tag(nil as CategoryModel?)
                    ForEach(allCategories) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.name)
                        }
                        .tag(category as CategoryModel?)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // Payment Method
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment Method")
                    .font(.headline)
                Picker("Payment Method", selection: $editPaymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        HStack {
                            Image(systemName: method.icon)
                            Text(method.rawValue)
                        }
                        .tag(method)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // Date
            VStack(alignment: .leading, spacing: 4) {
                Text("Date")
                    .font(.headline)
                DatePicker("", selection: $editDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Tags
            VStack(alignment: .leading, spacing: 4) {
                Text("Tags")
                    .font(.headline)
                Text("Separate tags with commas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("tag1, tag2, tag3", text: $editTags)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.headline)
                TextEditor(text: $editNotes)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Edit Actions
    private func startEditing(expense: ExpenseModel) {
        // Store original values for cancel
        originalValues = OriginalValues(
            amount: expense.amount,
            location: expense.location,
            category: expense.category,
            paymentMethod: expense.paymentMethod,
            date: expense.date,
            tags: expense.tags,
            notes: expense.notes
        )

        // Populate edit fields
        editAmount = String(format: "%.2f", expense.amount)
        editLocation = expense.location
        editCategory = expense.category
        editPaymentMethod = expense.paymentMethod
        editDate = expense.date
        editTags = expense.tags.joined(separator: ", ")
        editNotes = expense.notes

        isEditing = true
    }

    private func cancelEditing() {
        // Reset to original values (no changes needed as we didn't modify expense yet)
        originalValues = nil
        isEditing = false
    }

    private func saveChanges(expense: ExpenseModel) {
        // Parse amount
        let parsedAmount = Double(editAmount) ?? expense.amount

        // Parse tags
        let parsedTags = editTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Update expense properties
        expense.amount = parsedAmount
        expense.location = editLocation
        expense.category = editCategory
        expense.paymentMethod = editPaymentMethod
        expense.date = editDate
        expense.tags = parsedTags
        expense.notes = editNotes

        // Save via modelContext
        do {
            try modelContext.save()
            originalValues = nil
            isEditing = false
        } catch {
            Logger.data.error("Failed to save expense changes: \(error.localizedDescription)")
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
