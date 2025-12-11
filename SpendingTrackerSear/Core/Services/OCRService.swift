//
// OCRService.swift
// SpendingTracker
//
// Created by Developer on 10/5/2025.
// Purpose: Receipt OCR processing using Vision framework
//

import Vision
import UIKit
import OSLog

struct OCRService {
    
    /// Extract receipt data from an image using Vision OCR
    static func extractReceiptData(from image: UIImage) async throws -> ReceiptData {
        guard let cgImage = image.cgImage else {
            throw AppError.invalidInput
        }
        
        Logger.data.info("🔵 Starting OCR text recognition")
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    Logger.data.error("❌ Vision request failed: \(error.localizedDescription)")
                    continuation.resume(throwing: AppError.unknown(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    Logger.data.warning("⚠️ No text observations found")
                    continuation.resume(throwing: AppError.dataNotFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                Logger.data.info("🔵 OCR extracted \(recognizedText.count) lines of text")
                
                let receiptData = parseReceiptText(recognizedText)
                continuation.resume(returning: receiptData)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                Logger.data.error("❌ Vision handler failed: \(error.localizedDescription)")
                continuation.resume(throwing: AppError.unknown(error))
            }
        }
    }
    
    private static func parseReceiptText(_ lines: [String]) -> ReceiptData {
        var amount: Double?
        var location: String?
        var date: Date?
        var items: [String] = []
        
        // Combine all lines for better pattern matching
        let fullText = lines.joined(separator: " ")
        
        // Extract total amount using improved logic
        amount = extractAmount(from: fullText, lines: lines)
        
        // Extract merchant name (look in first 3 lines, avoid lines with $)
        for (index, line) in lines.enumerated() where index < 3 {
            if location == nil && line.count > 3 && !line.contains("$") && !line.lowercased().contains("receipt") {
                location = line.trimmingCharacters(in: .whitespaces)
                Logger.data.info("✅ Location found: \(location ?? "")")
                break
            }
        }
        
        // Extract date
        date = extractDate(from: lines)
        
        // Extract items (lines with prices but not total)
        for line in lines {
            if line.contains("$") &&
               !line.lowercased().contains("total") &&
               !line.lowercased().contains("amount") {
                items.append(line)
            }
        }
        
        Logger.data.info("✅ OCR processing complete: amount=\(amount ?? 0), location=\(location ?? "unknown"), date=\(date?.description ?? "nil")")
        
        return ReceiptData(
            amount: amount,
            location: location,
            date: date,
            items: items.isEmpty ? nil : items,
            rawText: fullText
        )
    }
    
    private static func extractAmount(from fullText: String, lines: [String]) -> Double? {
        // Priority 1: Highest priority keywords (150)
        let highestPriorityKeywords = [
            "total amount",
            "amount total"
        ]

        // Priority 2: High priority keywords (120)
        let highPriorityKeywords = [
            "grand total",
            "final total"
        ]

        // Priority 3: Medium-high priority - simple "Total" (100 + line index)
        // Handled separately to prefer later occurrences

        // Priority 4: Lower priority keywords (80)
        let lowerPriorityKeywords = [
            "amount due",
            "balance due",
            "you paid",
            "charge total",
            "total due"
        ]

        // Keywords to IGNORE - these are NOT the final amount
        let ignoreKeywords = [
            "subtotal",
            "sub-total",
            "sub total",
            "tax",
            "tip",
            "discount",
            "change",
            "cash",
            "card",
            "credit",
            "debit",
            "tendered",
            "payment",
            "paid with",
            "amount tendered"
        ]

        // Track all potential totals with their source
        struct PotentialTotal {
            let amount: Double
            let line: String
            let reason: String
            let priority: Int  // Higher = better
        }

        var potentialTotals: [PotentialTotal] = []

        // Amount pattern: matches $XX.XX or XX.XX
        let amountPattern = #"\$?\s*(\d+\.\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: amountPattern, options: []) else {
            Logger.data.warning("⚠️ Failed to create regex")
            return nil
        }

        // Process each line
        for (index, line) in lines.enumerated() {
            let lineLower = line.lowercased()

            // Skip lines with ignore keywords
            let shouldIgnore = ignoreKeywords.contains { lineLower.contains($0) }
            if shouldIgnore {
                Logger.data.info("   Ignoring line (excluded keyword): '\(line)'")
                continue
            }

            // Find amounts in this line
            let range = NSRange(line.startIndex..., in: line)
            let matches = regex.matches(in: line, range: range)

            for match in matches {
                if let amountRange = Range(match.range(at: 1), in: line) {
                    let amountString = String(line[amountRange])
                    if let amount = Double(amountString), amount > 0 {
                        // Determine priority based on keywords
                        var priority = 0
                        var reason = "no keyword match"

                        // Priority 1: Highest priority (150) - "Total Amount" / "Amount Total"
                        for keyword in highestPriorityKeywords {
                            if lineLower.contains(keyword) {
                                priority = 150
                                reason = "matched '\(keyword)'"
                                break
                            }
                        }

                        // Priority 2: High priority (120) - "Grand Total" / "Final Total"
                        if priority == 0 {
                            for keyword in highPriorityKeywords {
                                if lineLower.contains(keyword) {
                                    priority = 120
                                    reason = "matched '\(keyword)'"
                                    break
                                }
                            }
                        }

                        // Priority 3: Medium-high (100 + line index) - simple "Total"
                        // Check for exact "total" word boundary to avoid partial matches
                        if priority == 0 {
                            let totalPattern = #"\btotal\b"#
                            if let totalRegex = try? NSRegularExpression(pattern: totalPattern, options: .caseInsensitive) {
                                let lineRange = NSRange(lineLower.startIndex..., in: lineLower)
                                if totalRegex.firstMatch(in: lineLower, range: lineRange) != nil {
                                    priority = 100 + index
                                    reason = "matched 'total' (exact) at line \(index)"
                                }
                            }
                        }

                        // Priority 4: Lower priority (80) - "Amount Due" / "Balance Due" etc.
                        if priority == 0 {
                            for keyword in lowerPriorityKeywords {
                                if lineLower.contains(keyword) {
                                    priority = 80
                                    reason = "matched '\(keyword)'"
                                    break
                                }
                            }
                        }

                        potentialTotals.append(PotentialTotal(
                            amount: amount,
                            line: line,
                            reason: reason,
                            priority: priority
                        ))
                    }
                }
            }
        }

        // Log all potential totals
        print("🔍 Found potential totals:")
        for total in potentialTotals {
            print("   $\(String(format: "%.2f", total.amount)) (priority: \(total.priority)) - \(total.reason) - '\(total.line)'")
        }

        // Selection logic: Pick highest priority, then largest amount as tiebreaker
        let sorted = potentialTotals.sorted {
            if $0.priority != $1.priority {
                return $0.priority > $1.priority
            }
            return $0.amount > $1.amount
        }

        if let selected = sorted.first, selected.priority > 0 {
            print("✅ Selected amount: $\(String(format: "%.2f", selected.amount)) because \(selected.reason)")
            Logger.data.info("✅ Selected amount: $\(selected.amount) - \(selected.reason)")
            return selected.amount
        }

        // 3. Fallback: Use the LARGEST amount on the receipt
        if let selected = potentialTotals.max(by: { $0.amount < $1.amount }) {
            print("✅ Selected amount: $\(String(format: "%.2f", selected.amount)) because it's the largest amount (fallback)")
            Logger.data.info("✅ Selected amount: $\(selected.amount) - largest amount fallback")
            return selected.amount
        }

        print("⚠️ No amount found in receipt")
        Logger.data.warning("⚠️ No amount found in receipt")
        return nil
    }
    
    private static func extractDate(from lines: [String]) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formats = [
            "MM/dd/yyyy",
            "MM/dd/yy",
            "M/d/yyyy",
            "M/d/yy",
            "MM-dd-yyyy",
            "dd/MM/yyyy",
            "yyyy-MM-dd",
            "MMM dd, yyyy",
            "MMMM dd, yyyy"
        ]
        
        // Search through first 10 lines for dates
        for line in lines.prefix(10) {
            for format in formats {
                dateFormatter.dateFormat = format
                
                // Try to find date pattern in the line
                let words = line.split(separator: " ")
                for word in words {
                    let wordString = String(word).trimmingCharacters(in: CharacterSet.punctuationCharacters)
                    if let parsedDate = dateFormatter.date(from: wordString) {
                        // Sanity check: date should be within last 2 years and not in future
                        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
                        if parsedDate >= twoYearsAgo && parsedDate <= Date() {
                            Logger.data.info("✅ Date found: \(parsedDate)")
                            return parsedDate
                        }
                    }
                }
            }
        }
        
        // Also try full line matching
        for line in lines.prefix(10) {
            for format in formats {
                dateFormatter.dateFormat = format
                if let parsedDate = dateFormatter.date(from: line.trimmingCharacters(in: .whitespaces)) {
                    let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
                    if parsedDate >= twoYearsAgo && parsedDate <= Date() {
                        Logger.data.info("✅ Date found: \(parsedDate)")
                        return parsedDate
                    }
                }
            }
        }
        
        Logger.data.warning("⚠️ No date found in receipt")
        return nil
    }
}
