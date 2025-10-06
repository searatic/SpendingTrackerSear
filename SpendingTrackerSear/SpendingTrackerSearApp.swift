//
//  SpendingTrackerSearApp.swift
//  SpendingTrackerSear
//
//  Created by Leonard Cratic on 10/5/25.
//

import SwiftUI

@main
struct SpendingTrackerSearApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
