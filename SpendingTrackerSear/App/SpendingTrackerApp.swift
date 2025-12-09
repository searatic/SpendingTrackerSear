//
//  SpendingTrackerApp.swift
//  SpendingTrackerSear
//
//  Main app entry point
//

import SwiftUI
import SwiftData
import OSLog

@main
@MainActor
struct SpendingTrackerApp: App {
    @State private var dataController = DataController.live
    @State private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                ExpenseListView()
                    .navigationDestination(for: Route.self) { route in
                        route.destination
                            .toolbar(.visible, for: .navigationBar)
                    }
            }
            .modelContainer(dataController.container)
            // If Router is an ObservableObject, change this to .environmentObject(router)
            .environment(router)
            .onAppear {
                initializeDefaultCategories()
            }
        }
    }
    
    private func initializeDefaultCategories() {
        let context = dataController.container.mainContext
        let descriptor = FetchDescriptor<CategoryModel>()
        
        do {
            let existingCategories = try context.fetch(descriptor)
            
            if existingCategories.isEmpty {
                for defaultCategory in CategoryModel.defaultCategories {
                    context.insert(defaultCategory)
                }
                
                try context.save()
                Logger.app.info("Default categories initialized")
            }
        } catch {
            Logger.app.error("Failed to initialize categories: \(error.localizedDescription)")
        }
    }
}
