//
//  BudgetStatusCard.swift
//  SpendingTrackerSear
//
//  Created by Leonard Cratic on 10/5/25.
//

//
// BudgetStatusCard.swift
// SpendingTracker/Features/Shared/Components
//
// Created by Developer on 10/5/2025.
// Purpose: Budget status display card
//

import SwiftUI

struct BudgetStatusCard: View {
    let budget: BudgetModel
    let currentSpending: Double
    
    private var percentage: Double {
        (currentSpending / budget.monthlyLimit) * 100
    }
    
    private var status: BudgetStatus {
        budget.budgetStatus(currentSpending: currentSpending)
    }
    
    private var statusColor: Color {
        switch status {
        case .safe: return .green
        case .warning: return .yellow
        case .over: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let category = budget.category {
                    Image(systemName: category.icon)
                        .foregroundStyle(statusColor)
                    Text(category.name)
                        .font(.subheadline)
                        .bold()
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$\(currentSpending, specifier: "%.0f")")
                        .font(.title3)
                        .bold()
                    Text("/ $\(budget.monthlyLimit, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: min(percentage, 100), total: 100)
                    .tint(statusColor)
                
                Text(status.message)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            
            if status == .warning || status == .over {
                Text("⚠️ This puts your budget at risk")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
