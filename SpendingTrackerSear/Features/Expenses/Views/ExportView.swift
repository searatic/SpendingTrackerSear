//
// ExportView.swift
// SpendingTracker
//
// Created by Developer on 12/11/2025.
// Purpose: Date range selection for CSV export
//

import SwiftUI
import SwiftData
import OSLog

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExpenseModel.date, order: .reverse) private var allExpenses: [ExpenseModel]

    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    private var filteredExpenses: [ExpenseModel] {
        let startOfDay = Calendar.current.startOfDay(for: startDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) ?? endDate

        return allExpenses.filter { expense in
            expense.date >= startOfDay && expense.date < endOfDay
        }
    }

    private var totalAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                } header: {
                    Text("Date Range")
                }

                Section {
                    HStack {
                        Text("Expenses in range")
                        Spacer()
                        Text("\(filteredExpenses.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total amount")
                        Spacer()
                        Text("$\(totalAmount, specifier: "%.2f")")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Summary")
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        exportCSV()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Export to CSV")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(filteredExpenses.isEmpty || isExporting)
                }
            }
            .navigationTitle("Export Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportCSV() {
        isExporting = true
        errorMessage = nil

        do {
            let url = try generateCSV(from: filteredExpenses)
            exportURL = url
            showingShareSheet = true
        } catch {
            errorMessage = "Failed to export: \(error.localizedDescription)"
            Logger.data.error("CSV export error: \(error.localizedDescription)")
        }

        isExporting = false
    }

    private func generateCSV(from expenses: [ExpenseModel]) throws -> URL {
        var csvString = "Date,Category,Location,Amount,Payment Method,Notes,Tags\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for expense in expenses {
            let dateString = dateFormatter.string(from: expense.date)
            let category = expense.category?.name ?? "Uncategorized"
            let tags = expense.tags.joined(separator: "; ")

            // Escape quotes in fields
            let location = expense.location.replacingOccurrences(of: "\"", with: "\"\"")
            let notes = expense.notes.replacingOccurrences(of: "\"", with: "\"\"")

            csvString += "\"\(dateString)\",\"\(category)\",\"\(location)\",\"\(expense.amount)\",\"\(expense.paymentMethod.rawValue)\",\"\(notes)\",\"\(tags)\"\n"
        }

        let fileName = "expenses_\(formatDateForFilename(startDate))_to_\(formatDateForFilename(endDate)).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        Logger.data.info("CSV export created: \(fileName) with \(expenses.count) expenses")

        return fileURL
    }

    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    ExportView()
        .modelContainer(DataController.preview.container)
}
