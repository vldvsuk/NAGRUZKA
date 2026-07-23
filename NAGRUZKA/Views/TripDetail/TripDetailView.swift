//
//  TripDetailView.swift
//  NAGRUZKA
//

import SwiftUI

struct TripDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripId: UUID

    enum DetailTab: String, CaseIterable {
        case expenses = "Expenses"
        case balances = "Balances"
        case settle = "Settle Up"
    }

    @State private var tab: DetailTab = .expenses
    @State private var showingAddExpense = false
    @State private var showingInvite = false
    @State private var paidKeys: Set<String> = []
    @State private var selectedParticipant: Participant?

    private var trip: Trip { store.trip(id: tripId) ?? .placeholder }
    private var balances: [UUID: Double] { BalanceCalculator.balances(for: trip) }
    private var settlements: [Settlement] { BalanceCalculator.settlements(from: balances) }

    private var expensesByDate: [(date: Date, expenses: [Expense])] {
        let grouped = Dictionary(grouping: trip.expenses) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { (date: $0, expenses: grouped[$0]!) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            tabSelector
            ScrollView {
                content
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
            }
        }
        .background(AppTheme.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                        Text("All trips").font(.system(size: 13, weight: .semibold))
                    }
                }
                .tint(AppTheme.accent)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if tab == .expenses && trip.status == .active {
                fab
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseSheet(tripId: tripId)
        }
        .sheet(isPresented: $showingInvite) {
            InvitePeopleSheet(tripId: tripId)
        }
        .sheet(item: $selectedParticipant) { participant in
            ParticipantDetailSheet(tripId: tripId, participant: participant)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination.uppercased())
                        .font(.system(size: 10, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppTheme.foreground.opacity(0.4))
                    Text(trip.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.foreground)
                    Text("\(trip.dateRange) · \(trip.participants.count) people")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(AppTheme.mutedForeground)
                }
                Spacer()
                HStack(spacing: 8) {
                    HStack(spacing: -8) {
                        ForEach(trip.participants.prefix(4)) { p in
                            AvatarView(participant: p, size: 28)
                                .overlay(Circle().stroke(AppTheme.background, lineWidth: 2))
                        }
                        if trip.participants.count > 4 {
                            Circle().fill(AppTheme.chip).frame(width: 28, height: 28)
                                .overlay(
                                    Text("+\(trip.participants.count - 4)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                )
                        }
                    }
                    Button {
                        showingInvite = true
                    } label: {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 28, height: 28)
                            .overlay(Image(systemName: "plus").font(.system(size: 12, weight: .bold)).foregroundStyle(.white))
                    }
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL SPENT").font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
                    Text("\(trip.expenses.count) expenses").font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Text("€\(Formatting.money(trip.totalSpent))")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.hero)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(DetailTab.allCases, id: \.self) { t in
                Button {
                    tab = t
                } label: {
                    Text(t.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(tab == t ? AppTheme.accent : AppTheme.foreground.opacity(0.06))
                        .foregroundStyle(tab == t ? .white : AppTheme.foreground.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .expenses: expensesContent
        case .balances: balancesContent
        case .settle: settleContent
        }
    }

    // MARK: - Expenses tab

    private var expensesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if expensesByDate.isEmpty {
                emptyState(icon: "shippingbox.fill", title: "No expenses yet", subtitle: "Tap + to add the first one")
            }
            ForEach(expensesByDate, id: \.date) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(Formatting.shortDate(group.date).uppercased())
                        .font(.system(size: 10, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppTheme.foreground.opacity(0.35))
                    VStack(spacing: 0) {
                        ForEach(Array(group.expenses.enumerated()), id: \.element.id) { index, expense in
                            if index > 0 { Divider().padding(.leading, 60) }
                            expenseRow(expense)
                        }
                    }
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
                }
            }
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let payer = trip.participants.first { $0.id == expense.paidBy }
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(expense.category.color.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: expense.category.icon).font(.system(size: 14)).foregroundStyle(expense.category.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.foreground).lineLimit(1)
                if let payer {
                    HStack(spacing: 5) {
                        AvatarView(participant: payer, size: 13)
                        Text("\(payer.name) · \(expense.splitBetween.count)p")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(AppTheme.mutedForeground)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("€\(Formatting.money(expense.amount))").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.foreground)
                Text("€\(Formatting.money(expense.sharePerPerson))/ea").font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Balances tab

    private var balancesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NET BALANCES").font(.system(size: 10, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            ForEach(trip.participants) { p in
                let bal = balances[p.id] ?? 0
                let pos = bal > 0.01
                let neg = bal < -0.01
                let color: Color = pos ? AppTheme.positive : neg ? AppTheme.negative : AppTheme.mutedForeground
                Button {
                    selectedParticipant = p
                } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            AvatarView(participant: p, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.foreground)
                                Text(pos ? "is owed" : neg ? "owes" : "settled up").font(.system(size: 10, design: .monospaced)).foregroundStyle(color)
                            }
                            Spacer()
                            Text("\(pos ? "+" : neg ? "−" : "")€\(Formatting.money(abs(bal)))")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundStyle(color)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.foreground.opacity(0.2))
                        }
                        GeometryReader { geo in
                            let ratio = trip.totalSpent > 0 ? min(1, abs(bal) / (trip.totalSpent * 0.6)) : 0
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppTheme.chip)
                                Capsule().fill(color).frame(width: geo.size.width * ratio)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("BY CATEGORY")
                .font(.system(size: 10, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
                .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach(Array(categoryTotals.enumerated()), id: \.element.category) { index, item in
                    if index > 0 { Divider().padding(.leading, 56) }
                    categoryRow(item.category, total: item.total)
                }
            }
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
        }
    }

    private var categoryTotals: [(category: ExpenseCategory, total: Double)] {
        ExpenseCategory.allCases.compactMap { cat in
            let total = trip.expenses.filter { $0.category == cat }.reduce(0) { $0 + $1.amount }
            return total > 0 ? (category: cat, total: total) : nil
        }
    }

    private func categoryRow(_ cat: ExpenseCategory, total: Double) -> some View {
        let pct = trip.totalSpent > 0 ? Int((total / trip.totalSpent * 100).rounded()) : 0
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(cat.color.opacity(0.1)).frame(width: 28, height: 28)
                Image(systemName: cat.icon).font(.system(size: 12)).foregroundStyle(cat.color)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(cat.rawValue).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.foreground)
                    Spacer()
                    Text("€\(Formatting.money(total))").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.foreground)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.chip)
                        Capsule().fill(cat.color).frame(width: geo.size.width * CGFloat(pct) / 100)
                    }
                }
                .frame(height: 3)
            }
            Text("\(pct)%").font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.35)).frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Settle tab

    private var settleContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(settlements.count) PAYMENT\(settlements.count == 1 ? "" : "S") TO CLOSE THE TRIP")
                .font(.system(size: 10, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))

            ForEach(settlements) { settlement in
                settlementCard(settlement)
            }

            if settlements.isEmpty {
                VStack(spacing: 10) {
                    ZStack {
                        Circle().fill(AppTheme.positive.opacity(0.1)).frame(width: 48, height: 48)
                        Image(systemName: "checkmark").font(.system(size: 20, weight: .bold)).foregroundStyle(AppTheme.positive)
                    }
                    Text("All settled up").font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.foreground)
                    Text("No payments needed").font(.system(size: 11, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        }
    }

    private func settlementCard(_ settlement: Settlement) -> some View {
        let from = trip.participants.first { $0.id == settlement.from }
        let to = trip.participants.first { $0.id == settlement.to }
        let paid = paidKeys.contains(settlement.id)

        return VStack(spacing: 10) {
            HStack {
                HStack(spacing: 10) {
                    if let from { AvatarView(participant: from, size: 38) }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("pays").font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.35))
                        Text(from?.name ?? "").font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.foreground)
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("€\(Formatting.money(settlement.amount))").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.accent)
                    Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(AppTheme.foreground.opacity(0.2))
                }
                Spacer()
                HStack(spacing: 10) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("receives").font(.system(size: 10, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.35))
                        Text(to?.name ?? "").font(.system(size: 13, weight: .semibold)).foregroundStyle(AppTheme.foreground)
                    }
                    if let to { AvatarView(participant: to, size: 38) }
                }
            }
            Button {
                if paid { paidKeys.remove(settlement.id) } else { paidKeys.insert(settlement.id) }
            } label: {
                HStack(spacing: 6) {
                    if paid {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                        Text("Marked as paid")
                    } else {
                        Text("Mark as paid")
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(paid ? AppTheme.positive.opacity(0.12) : AppTheme.chip)
                .foregroundStyle(paid ? AppTheme.positive : AppTheme.foreground.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .background(paid ? AppTheme.positive.opacity(0.06) : AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(paid ? AppTheme.positive.opacity(0.3) : AppTheme.border, lineWidth: 1))
    }

    // MARK: - Shared bits

    private var fab: some View {
        Button {
            showingAddExpense = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppTheme.accent.opacity(0.35), radius: 12, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(AppTheme.foreground.opacity(0.06)).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20)).foregroundStyle(AppTheme.foreground.opacity(0.25))
            }
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(AppTheme.foreground.opacity(0.5))
            Text(subtitle).font(.system(size: 11, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }
}

#Preview {
    let store = AppStore()
    return NavigationStack {
        TripDetailView(tripId: store.trips[0].id)
    }
    .environment(store)
}
