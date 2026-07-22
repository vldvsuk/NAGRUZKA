//
//  NAGRUZKAApp.swift
//  NAGRUZKA
//
//  Created by Влад Івасюк on 22/07/2026.
//

import SwiftUI

@main
struct NAGRUZKAApp: App {
    @State private var store = TripStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
