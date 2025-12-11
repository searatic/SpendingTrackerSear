//
// AddExpenseView.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: Form view for adding new expenses with receipt scanning
//

import SwiftUI
import SwiftData
import PhotosUI
import OSLog

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddExpenseViewModel(modelContext: DataController.live.container.mainContext)

    // Optional initial data from receipt scan (passed from main menu)
    var initialReceiptData: ReceiptData?

    // IMPORTANT: Explicitly specify CategoryModel type
    @Query(sort: \CategoryModel.name) private var categories: [CategoryModel]

    // Photo picker state
    @State private var showingPhotoOptions = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        Form {
            // Receipt Scanner Section
            Section {
                Button {
                    showingPhotoOptions = true
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
        .confirmationDialog("Scan Receipt", isPresented: $showingPhotoOptions, titleVisibility: .visible) {
            Button("Take Photo") {
                viewModel.showingScanner = true
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                await processSelectedPhoto(newValue)
            }
        }
        .onAppear {
            viewModel.configure(with: ExpenseService(modelContext: modelContext))

            // If we have initial receipt data (from main menu scan), process it
            if let receiptData = initialReceiptData {
                viewModel.pendingScanData = receiptData
                viewModel.shouldProcessScan = true
            }
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

    // MARK: - Photo Picker Processing
    private func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            // Load image data from the selected photo
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Store photo data for receipt attachment
                viewModel.photoData = uiImage.jpegData(compressionQuality: 0.8)
                viewModel.hasPhoto = true

                // Process through OCR to extract receipt data
                let receiptData = try await OCRService.extractReceiptData(from: uiImage)

                // Set pending scan data and trigger processing
                await MainActor.run {
                    viewModel.pendingScanData = receiptData
                    viewModel.shouldProcessScan = true
                }

                Logger.data.info("🟢 Photo picker: Image processed through OCR")
            }
        } catch {
            Logger.data.error("Failed to load selected photo: \(error.localizedDescription)")
        }

        // Reset the selection
        await MainActor.run {
            selectedPhotoItem = nil
        }
    }
}

#Preview {
    NavigationStack {
        AddExpenseView()
            .modelContainer(DataController.preview.container)
    }
}
