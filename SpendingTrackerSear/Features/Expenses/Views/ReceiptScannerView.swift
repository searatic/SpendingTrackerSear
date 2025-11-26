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
                    } else if let data = scannedData {
                        // Show extracted data
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Data")
                                .font(.headline)
                            
                            if let amount = data.amount {
                                HStack {
                                    Text("Amount:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("$\(amount, specifier: "%.2f")")
                                        .bold()
                                }
                            }
                            
                            if let location = data.location {
                                HStack {
                                    Text("Location:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(location)
                                }
                            }
                            
                            if let date = data.date {
                                HStack {
                                    Text("Date:")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(date, style: .date)
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
                        // Retake photo
                        scannedImage = nil
                        scannedData = nil
                        errorMessage = nil
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
                    Logger.data.info("✅ OCR processing complete")
                    
                    if let amount = data.amount {
                        Logger.data.info("   Amount: $\(amount)")
                    }
                    if let location = data.location {
                        Logger.data.info("   Location: \(location)")
                    }
                    if let date = data.date {
                        Logger.data.info("   Date: \(date)")
                    }
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
        guard let data = scannedData else { return }
        
        Logger.data.info("🔵 Use button tapped")
        
        // Set the data via binding
        pendingScanData = data
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
