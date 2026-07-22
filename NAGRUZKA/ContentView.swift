//
//  ContentView.swift
//  NAGRUZKA
//
//  Created by Влад Івасюк on 22/07/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ParticipantsView()
                .tabItem { Label("Participants", systemImage: "person.2") }

            ExpensesView()
                .tabItem { Label("Expenses", systemImage: "list.bullet") }

            BalancesView()
                .tabItem { Label("Balances", systemImage: "chart.bar") }
        }
    }
}

#Preview {
    ContentView()
        .environment(TripStore())
}
