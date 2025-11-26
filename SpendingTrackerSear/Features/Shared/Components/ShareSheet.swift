//
//  ShareSheet.swift
//  SpendingTrackerSear
//
//  Created by Leonard Cratic on 10/5/25.
//

//
// ShareSheet.swift
// SpendingTracker/Features/Shared/Components
//
// Created by Developer on 10/5/2025.
// Purpose: System share sheet wrapper
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
