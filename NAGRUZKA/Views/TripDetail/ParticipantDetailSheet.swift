//
//  ParticipantDetailSheet.swift
//  NAGRUZKA
//
//  Tapping a person in the Balances tab opens this: who specifically they
//  owe or are owed by, and which expenses caused each part of their balance.
//

import SwiftUI

struct ParticipantDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripId: UUID
    let participant: Participant

    private var trip: Trip { store.trip(id: tripId) ?? .placeholder }
    private var balance: Double { BalanceCalculator.balances(for: trip)[participant.id] ?? 0 }

    private var pairwise: [(participant: Participant, amount: Double)] {
        let net = BalanceCalculator.pairwiseNet(for: participant.id, in: trip)
        return trip.participants
            .filter { $0.id != participant.id }
            .compactMap { p -> (participant: Participant, amount: Double)? in
                let amount = net[p.id] ?? 0
                return abs(amount) > 0.01 ? (participant: p, amount: amount) : nil
            }
            .sorted { abs($0.amount) > abs($1.amount) }
    }

    private var expenseBreakdown: [(expense: Expense, netEffect: Double)] {
        BalanceCalculator.expenseBreakdown(for: participant.id, in: trip)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if !pairwise.isEmpty {
                        section(title: "Who's involved") {
                            VStack(spacing: 10) {
                                ForEach(pairwise, id: \.participant.id) { item in
                                    pairwiseRow(item.participant, amount: item.amount)
                                }
                            }
                        }
                    }

                    if !expenseBreakdown.isEmpty {
                        section(title: "For what") {
                            VStack(spacing: 0) {
                                ForEach(Array(expenseBreakdown.enumerated()), id: \.element.expense.id) { index, item in
                                    if index > 0 { Divider().padding(.leading, 60) }
                                    expenseRow(item.expense, netEffect: item.netEffect)
                                }
                            }
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle(participant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        let pos = balance > 0.01
        let neg = balance < -0.01
        let color: Color = pos ? AppTheme.positive : neg ? AppTheme.negative : AppTheme.mutedForeground
        return VStack(spacing: 10) {
            AvatarView(participant: participant, size: 64)
            Text(participant.name).font(.system(size: 18, weight: .bold)).foregroundStyle(AppTheme.foreground)
            Text("\(pos ? "+" : neg ? "−" : "")€\(Formatting.money(abs(balance)))")
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(pos ? "is owed overall" : neg ? "owes overall" : "settled up")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            content()
        }
    }

    private func pairwiseRow(_ other: Participant, amount: Double) -> some View {
        let owesThem = amount < 0
        let color: Color = owesThem ? AppTheme.negative : AppTheme.positive
        return HStack(spacing: 12) {
            AvatarView(participant: other, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(other.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.foreground)
                Text(owesThem ? "\(participant.name) owes \(other.name)" : "\(other.name) owes \(participant.name)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppTheme.mutedForeground)
            }
            Spacer()
            Text("€\(Formatting.money(abs(amount)))")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border, lineWidth: 1))
    }

    private func expenseRow(_ expense: Expense, netEffect: Double) -> some View {
        let payer = trip.participants.first { $0.id == expense.paidBy }
        let pos = netEffect > 0.01
        let neg = netEffect < -0.01
        let color: Color = pos ? AppTheme.positive : neg ? AppTheme.negative : AppTheme.mutedForeground
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(expense.category.color.opacity(0.1)).frame(width: 34, height: 34)
                Image(systemName: expense.category.icon).font(.system(size: 13)).foregroundStyle(expense.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description).font(.system(size: 12, weight: .semibold)).foregroundStyle(AppTheme.foreground).lineLimit(1)
                Text("paid by \(payer?.name ?? "?") · \(Formatting.shortDate(expense.date))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppTheme.mutedForeground)
            }
            Spacer()
            Text("\(pos ? "+" : neg ? "−" : "")€\(Formatting.money(abs(netEffect)))")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    let store = AppStore()
    return ParticipantDetailSheet(tripId: store.trips[0].id, participant: store.trips[0].participants[0])
        .environment(store)
}
