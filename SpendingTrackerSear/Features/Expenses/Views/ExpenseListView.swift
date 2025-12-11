//
// ExpenseListView.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Main expense list with budget warnings
//

import SwiftUI
import SwiftData
import PhotosUI
import OSLog

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    @State private var viewModel = ExpenseListViewModel()

    @Query(sort: \ExpenseModel.date, order: .reverse) private var allExpenses: [ExpenseModel]
    @Query var categories: [CategoryModel]
    @Query var budgets: [BudgetModel]

    // Scan receipt state
    @State private var showingScanOptions = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingReceipt = false
    
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

                    Button {
                        showingScanOptions = true
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
                        viewModel.showingExportSheet = true
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
            ExportView()
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
        // Scan Receipt action sheet
        .confirmationDialog("Scan Receipt", isPresented: $showingScanOptions, titleVisibility: .visible) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        // Camera sheet
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                processScannedImage(image)
            }
        }
        // Photo picker
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                await processSelectedPhoto(newValue)
            }
        }
        // Processing overlay
        .overlay {
            if isProcessingReceipt {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing receipt...")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    // MARK: - Receipt Processing

    private func processScannedImage(_ image: UIImage) {
        isProcessingReceipt = true

        Task {
            do {
                let receiptData = try await OCRService.extractReceiptData(from: image)
                await MainActor.run {
                    isProcessingReceipt = false
                    router.navigate(to: .addExpenseWithScan(receiptData: receiptData))
                }
            } catch {
                await MainActor.run {
                    isProcessingReceipt = false
                    viewModel.errorMessage = "Failed to process receipt: \(error.localizedDescription)"
                }
            }
        }
    }

    private func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        await MainActor.run {
            isProcessingReceipt = true
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                let receiptData = try await OCRService.extractReceiptData(from: uiImage)
                await MainActor.run {
                    isProcessingReceipt = false
                    selectedPhotoItem = nil
                    router.navigate(to: .addExpenseWithScan(receiptData: receiptData))
                }
            } else {
                await MainActor.run {
                    isProcessingReceipt = false
                    selectedPhotoItem = nil
                }
            }
        } catch {
            await MainActor.run {
                isProcessingReceipt = false
                selectedPhotoItem = nil
                viewModel.errorMessage = "Failed to process photo: \(error.localizedDescription)"
            }
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
