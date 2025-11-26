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
        // Strategy 1: Look for total line specifically first
        let totalPatterns = [
            #"(?:total|amount due|balance)[:\s]*\$?(\d+\.?\d*)"#,
            #"(?:total)[:\s]*(\d+\.\d{2})"#
        ]
        
        for pattern in totalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(fullText.startIndex..., in: fullText)
                if let match = regex.firstMatch(in: fullText, range: range) {
                    if let amountRange = Range(match.range(at: 1), in: fullText) {
                        let amountString = String(fullText[amountRange])
                        if let amount = Double(amountString) {
                            Logger.data.info("✅ Amount found via total pattern: $\(amount)")
                            return amount
                        }
                    }
                }
            }
        }
        
        // Strategy 2: Find largest amount in the receipt (likely the total)
        let amountPattern = #"\$?(\d+\.\d{2})"#
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []) {
            var amounts: [Double] = []
            
            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                let matches = regex.matches(in: line, range: range)
                
                for match in matches {
                    if let amountRange = Range(match.range(at: 1), in: line) {
                        let amountString = String(line[amountRange])
                        if let amount = Double(amountString) {
                            amounts.append(amount)
                            Logger.data.info("   Found amount: $\(amount) in line: '\(line)'")
                        }
                    }
                }
            }
            
            // Return the largest amount found (usually the total)
            if let maxAmount = amounts.max() {
                Logger.data.info("✅ Selected largest amount: $\(maxAmount)")
                return maxAmount
            }
        }
        
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
