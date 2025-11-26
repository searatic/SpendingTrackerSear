//
// ReceiptData.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: Data structure for OCR-extracted receipt information
//

import Foundation

struct ReceiptData {
    var amount: Double?
    var location: String?
    var date: Date?
    var items: [String]?
    var rawText: String?
    
    init(
        amount: Double? = nil,
        location: String? = nil,
        date: Date? = nil,
        items: [String]? = nil,
        rawText: String? = nil
    ) {
        self.amount = amount
        self.location = location
        self.date = date
        self.items = items
        self.rawText = rawText
    }
}
