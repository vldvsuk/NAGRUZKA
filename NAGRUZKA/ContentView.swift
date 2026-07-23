//
//  ContentView.swift
//  NAGRUZKA
//
//  Created by Влад Івасюк on 22/07/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: Tab = .home
    @State private var path = NavigationPath()

    enum Tab {
        case home, trips, settings
    }

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                DashboardView(onOpen: { path.append($0) })
                    .tag(Tab.home)
                    .tabItem { Label("Home", systemImage: "house.fill") }

                TripsListView(onOpen: { path.append($0) })
                    .tag(Tab.trips)
                    .tabItem { Label("Trips", systemImage: "briefcase.fill") }

                SettingsView()
                    .tag(Tab.settings)
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(AppTheme.accent)
            .navigationDestination(for: UUID.self) { tripId in
                TripDetailView(tripId: tripId)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppStore())
}
