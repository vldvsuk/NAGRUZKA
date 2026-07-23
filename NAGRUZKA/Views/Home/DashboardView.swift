//
//  DashboardView.swift
//  NAGRUZKA
//

import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    let onOpen: (UUID) -> Void

    private var activeTrips: [Trip] { store.trips.filter { $0.status == .active } }
    private var totalSpent: Double { store.trips.reduce(0) { $0 + $1.totalSpent } }
    private var totalExpenses: Int { store.trips.reduce(0) { $0 + $1.expenses.count } }

    private var recentExpenses: [(expense: Expense, trip: Trip)] {
        Array(
            store.trips
                .flatMap { trip in trip.expenses.map { (expense: $0, trip: trip) } }
                .sorted { $0.expense.date > $1.expense.date }
                .prefix(4)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if !activeTrips.isEmpty {
                    section(title: "Active trips") {
                        VStack(spacing: 10) {
                            ForEach(activeTrips) { trip in
                                Button {
                                    onOpen(trip.id)
                                } label: {
                                    TripCardView(trip: trip, myBalance: BalanceCalculator.balances(for: trip)[AppStore.currentUserId] ?? 0)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !recentExpenses.isEmpty {
                    section(title: "Recent activity") {
                        VStack(spacing: 0) {
                            ForEach(Array(recentExpenses.enumerated()), id: \.offset) { index, item in
                                if index > 0 { Divider().padding(.leading, 60) }
                                recentRow(item.expense, trip: item.trip)
                            }
                        }
                        .background(AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GOOD MORNING")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            Text("Vlad")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.foreground)
                .padding(.bottom, 12)

            heroCard
        }
        .padding(.top, 12)
    }

    private var heroCard: some View {
        let balance = store.overallBalance
        let isOwed = balance > 0.01
        let owes = balance < -0.01
        let color: Color = isOwed ? AppTheme.positive : owes ? AppTheme.negative : .white

        return VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OVERALL BALANCE")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(isOwed ? "+" : owes ? "−" : "")€\(Formatting.money(abs(balance)))")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                    Text(isOwed ? "you are owed" : owes ? "you owe" : "all settled up")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(color)
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            HStack(spacing: 8) {
                statTile(label: "Active trips", value: "\(activeTrips.count)")
                statTile(label: "Total spent", value: "€\(Int(totalSpent.rounded()))")
                statTile(label: "Expenses", value: "\(totalExpenses)")
            }
        }
        .padding(16)
        .background(AppTheme.hero)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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

    private func recentRow(_ expense: Expense, trip: Trip) -> some View {
        let payer = trip.participants.first { $0.id == expense.paidBy }
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(expense.category.color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: expense.category.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(expense.category.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(expense.description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.foreground)
                    .lineLimit(1)
                Text("\(trip.name) · \(Formatting.shortDate(expense.date))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(AppTheme.mutedForeground)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("€\(Formatting.money(expense.amount))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.foreground)
                if let payer {
                    AvatarView(participant: payer, size: 12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    DashboardView(onOpen: { _ in })
        .environment(AppStore())
}
