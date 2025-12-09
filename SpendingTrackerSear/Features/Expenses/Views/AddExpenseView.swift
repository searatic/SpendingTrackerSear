//
// AddExpenseView.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: Form view for adding new expenses with receipt scanning
//

import SwiftUI
import SwiftData
import OSLog

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddExpenseViewModel(modelContext: DataController.live.container.mainContext)
    
    // IMPORTANT: Explicitly specify CategoryModel type
    @Query(sort: \CategoryModel.name) private var categories: [CategoryModel]
    
    var body: some View {
        Form {
            // Receipt Scanner Section
            Section {
                Button {
                    viewModel.showingScanner = true
                } label: {
                    Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                }
            } header: {
                Text("Quick Entry")
            }

            // Amount Section
            Section {
                TextField("Amount", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Amount")
            }

            // Location Section
            Section {
                TextField("Location", text: $viewModel.location)
            } header: {
                Text("Location")
            }

            // Category Section
            Section {
                Picker("Category", selection: $viewModel.category) {
                    Text("Select Category (Optional)").tag(nil as CategoryModel?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as CategoryModel?)
                    }
                }
            } header: {
                Text("Category")
            }

            // Payment Method Section
            Section {
                Picker("Payment Method", selection: $viewModel.paymentMethod) {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }

                Toggle("Payment Method Required", isOn: $viewModel.paymentMethodRequired)
            } header: {
                Text("Payment Method")
            } footer: {
                Text("Enable for cash-only vendors or specific payment requirements")
            }

            // Details Section
            Section {
                DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)

                TextField("Tags (comma-separated)", text: $viewModel.tags)

                TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Details")
            }

            // Recurring Section
            Section {
                Toggle("Recurring Expense", isOn: $viewModel.isRecurring)

                if viewModel.isRecurring {
                    Picker("Frequency", selection: $viewModel.recurringFrequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
            } header: {
                Text("Recurring")
            }

            // Photo Section
            Section {
                Button {
                    viewModel.showingCamera = true
                } label: {
                    Label(viewModel.hasPhoto ? "Change Photo" : "Add Photo",
                          systemImage: viewModel.hasPhoto ? "photo.fill" : "camera")
                }

                if viewModel.hasPhoto {
                    Button(role: .destructive) {
                        viewModel.photoData = nil
                        viewModel.hasPhoto = false
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            } header: {
                Text("Receipt Photo")
            }

            // Error Message
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Add Expense")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveExpense()
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.validateInput() || viewModel.isLoading)
            }
        }
        .sheet(isPresented: $viewModel.showingScanner) {
            ReceiptScannerView(
                pendingScanData: $viewModel.pendingScanData,
                shouldProcessScan: $viewModel.shouldProcessScan
            )
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView { image in
                viewModel.photoData = image.jpegData(compressionQuality: 0.8)
                viewModel.hasPhoto = true
            }
        }
        .onAppear {
            viewModel.configure(with: ExpenseService(modelContext: modelContext))
        }
        // Monitor for scanned data and process it
        .onChange(of: viewModel.shouldProcessScan) { oldValue, newValue in
            if newValue == true {
                Logger.data.info("🟢 shouldProcessScan changed to true in AddExpenseView")
                Logger.data.info("🟢 Calling processPendingScan()")
                viewModel.processPendingScan()
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddExpenseView()
            .modelContainer(DataController.preview.container)
    }
}
