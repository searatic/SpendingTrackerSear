//
// ReceiptScannerView.swift
// SpendingTracker
//
// Created by Leonard Cratic on 10/11/2025.
// Purpose: Receipt scanning view with camera and OCR processing
//

import SwiftUI
import OSLog

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCamera = false
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var scannedData: ReceiptData?
    @State private var errorMessage: String?

    // Editable fields for user correction
    @State private var editableAmount: String = ""
    @State private var editableLocation: String = ""

    // NEW: Direct binding to ViewModel state
    @Binding var pendingScanData: ReceiptData?
    @Binding var shouldProcessScan: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = scannedImage {
                    // Show scanned image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    if isProcessing {
                        ProgressView("Processing receipt...")
                            .padding()
                    } else if scannedData != nil {
                        // Show extracted data with editable fields
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Data")
                                .font(.headline)

                            Text("Tap to edit if OCR made mistakes")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Editable Amount
                            HStack {
                                Text("Amount:")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .leading)
                                HStack {
                                    Text("$")
                                    TextField("0.00", text: $editableAmount)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }

                            // Editable Location
                            HStack {
                                Text("Location:")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .leading)
                                TextField("Store name", text: $editableLocation)
                                    .textFieldStyle(.roundedBorder)
                            }

                            // Date (read-only for now)
                            if let date = scannedData?.date {
                                HStack {
                                    Text("Date:")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 70, alignment: .leading)
                                    Text(date, style: .date)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        Button {
                            useScannedData()
                        } label: {
                            Text("Use This Data")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .padding()
                    }
                    
                    Button {
                        // Retake photo - reset all state
                        scannedImage = nil
                        scannedData = nil
                        errorMessage = nil
                        editableAmount = ""
                        editableLocation = ""
                        showingCamera = true
                    } label: {
                        Label("Retake Photo", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                    
                } else {
                    // Initial state - show camera button
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)
                        
                        Text("Scan a Receipt")
                            .font(.title2)
                            .bold()
                        
                        Text("Take a photo of your receipt to automatically extract transaction details")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Open Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    scannedImage = image
                    processReceipt(image)
                }
            }
        }
    }
    
    private func processReceipt(_ image: UIImage) {
        isProcessing = true
        errorMessage = nil

        Logger.data.info("🔵 Starting OCR processing")

        Task {
            do {
                let data = try await OCRService.extractReceiptData(from: image)
                await MainActor.run {
                    scannedData = data
                    isProcessing = false

                    // Populate editable fields with OCR results
                    if let amount = data.amount {
                        editableAmount = String(format: "%.2f", amount)
                        Logger.data.info("   Amount: $\(amount)")
                    } else {
                        editableAmount = ""
                    }

                    editableLocation = data.location ?? ""
                    if let location = data.location {
                        Logger.data.info("   Location: \(location)")
                    }

                    if let date = data.date {
                        Logger.data.info("   Date: \(date)")
                    }

                    Logger.data.info("✅ OCR processing complete")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to process receipt: \(error.localizedDescription)"
                    isProcessing = false
                    Logger.data.error("❌ OCR processing failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func useScannedData() {
        guard let originalData = scannedData else { return }

        Logger.data.info("🔵 Use button tapped")

        // Parse the editable amount (use user's edited value)
        let finalAmount = Double(editableAmount)

        // Use the edited location (trimmed)
        let finalLocation = editableLocation.trimmingCharacters(in: .whitespaces)

        // Create new ReceiptData with user-edited values
        let editedData = ReceiptData(
            amount: finalAmount,
            location: finalLocation.isEmpty ? nil : finalLocation,
            date: originalData.date,
            items: originalData.items,
            rawText: originalData.rawText
        )

        Logger.data.info("🔵 Using edited values - Amount: $\(finalAmount ?? 0), Location: \(finalLocation)")

        // Set the data via binding
        pendingScanData = editedData
        shouldProcessScan = true

        Logger.data.info("🔵 Data set in binding - pendingScanData assigned")
        Logger.data.info("🔵 shouldProcessScan = true")

        // Dismiss after a tiny delay to ensure state propagates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            Logger.data.info("🔵 Dismissing scanner")
            dismiss()
        }
    }
}

#Preview {
    @Previewable @State var pendingData: ReceiptData? = nil
    @Previewable @State var shouldProcess: Bool = false
    
    ReceiptScannerView(
        pendingScanData: $pendingData,
        shouldProcessScan: $shouldProcess
    )
}
