//
// ChartsView.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Spending visualizations and trends
//

import SwiftUI
import SwiftData
import Charts

struct ChartsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [ExpenseModel]
    @Query private var categories: [CategoryModel]
    @State private var selectedPeriod: ChartPeriod = .month
    
    var categorySpending: [(CategoryModel, Double)] {
        let grouped = Dictionary(grouping: filteredExpenses) { $0.category }
        return grouped.compactMap { category, expenses in
            guard let cat = category else { return nil }
            let total = expenses.reduce(0) { $0 + $1.amount }
            return (cat, total)
        }.sorted { $0.1 > $1.1 }
    }
    
    var dailySpending: [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.0 < $1.0 }
    }
    
    var filteredExpenses: [ExpenseModel] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return expenses.filter { $0.date >= startOfWeek }
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return expenses.filter { $0.date >= startOfMonth }
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return expenses.filter { $0.date >= startOfYear }
        }
    }
    
    var totalSpending: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var averageDaily: Double {
        guard !dailySpending.isEmpty else { return 0 }
        return totalSpending / Double(dailySpending.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Summary Stats
                HStack(spacing: 20) {
                    StatCard(title: "Total", value: "$\(totalSpending.formatted(.number.precision(.fractionLength(0))))")
                    StatCard(title: "Daily Avg", value: "$\(averageDaily.formatted(.number.precision(.fractionLength(0))))")
                    StatCard(title: "Transactions", value: "\(filteredExpenses.count)")
                }
                .padding(.horizontal)
                
                // Category Breakdown (Pie Chart)
                VStack(alignment: .leading, spacing: 12) {
                    Text("By Category")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart(categorySpending, id: \.0.id) { category, amount in
                        SectorMark(
                            angle: .value("Amount", amount),
                            innerRadius: .ratio(0.5)
                        )
                        .foregroundStyle(by: .value("Category", category.name))
                    }
                    .frame(height: 250)
                    .padding()
                    
                    // Legend
                    ForEach(categorySpending, id: \.0.id) { category, amount in
                        HStack {
                            Circle()
                                .fill(Color(category.color))
                                .frame(width: 12, height: 12)
                            Text(category.name)
                                .font(.caption)
                            Spacer()
                            Text("$\(amount.formatted(.number.precision(.fractionLength(0))))")
                                .font(.caption)
                                .bold()
                            Text("(\(Int((amount/totalSpending)*100))%)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Daily Trend (Line Chart)
                if !dailySpending.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Spending")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(dailySpending, id: \.0) { date, amount in
                            LineMark(
                                x: .value("Date", date),
                                y: .value("Amount", amount)
                            )
                            .foregroundStyle(.blue)
                            
                            AreaMark(
                                x: .value("Date", date),
                                y: .value("Amount", amount)
                            )
                            .foregroundStyle(.blue.opacity(0.2))
                        }
                        .frame(height: 200)
                        .padding()
                    }
                }
                
                // Spending Prediction
                if dailySpending.count >= 7 {
                    SpendingPredictionCard(
                        currentSpending: totalSpending,
                        dailyAverage: averageDaily,
                        period: selectedPeriod
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Charts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SpendingPredictionCard: View {
    let currentSpending: Double
    let dailyAverage: Double
    let period: ChartPeriod
    
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .week:
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: now))!
            return calendar.dateComponents([.day], from: now, to: endOfWeek).day ?? 0
        case .month:
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.startOfDay(for: now))!
            return calendar.dateComponents([.day], from: now, to: endOfMonth).day ?? 0
        case .year:
            return 365
        }
    }
    
    private var projectedTotal: Double {
        currentSpending + (dailyAverage * Double(daysRemaining))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending Prediction")
                .font(.headline)
            
            Text("At current pace, you'll spend approximately $\(projectedTotal.formatted(.number.precision(.fractionLength(0)))) this \(period.rawValue.lowercased())")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Average")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(dailyAverage.formatted(.number.precision(.fractionLength(0))))")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Projected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(projectedTotal.formatted(.number.precision(.fractionLength(0))))")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

enum ChartPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}
