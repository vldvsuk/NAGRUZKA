//
//  BalancesView.swift
//  NAGRUZKA
//

import SwiftUI

struct BalancesView: View {
    @Environment(TripStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section("Balances") {
                    if store.participants.isEmpty {
                        Text("Add participants to see balances")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.participants) { participant in
                        HStack {
                            Text(participant.name)
                            Spacer()
                            let balance = store.balances[participant.id] ?? 0
                            Text(balance, format: .currency(code: "EUR"))
                                .foregroundStyle(balance >= 0 ? .green : .red)
                        }
                    }
                }

                Section("Settle up") {
                    if store.settlements.isEmpty {
                        Text("All settled up!")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.settlements) { settlement in
                        HStack {
                            Text(store.name(for: settlement.fromId))
                            Image(systemName: "arrow.right")
                            Text(store.name(for: settlement.toId))
                            Spacer()
                            Text(settlement.amount, format: .currency(code: "EUR"))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Balances")
        }
    }
}

#Preview {
    BalancesView()
        .environment(TripStore())
}
