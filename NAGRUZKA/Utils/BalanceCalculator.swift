//
//  BalanceCalculator.swift
//  NAGRUZKA
//

import Foundation

enum BalanceCalculator {
    static func balances(for trip: Trip) -> [UUID: Double] {
        var result: [UUID: Double] = [:]
        for participant in trip.participants {
            result[participant.id] = 0
        }
        for expense in trip.expenses {
            guard !expense.splitBetween.isEmpty else { continue }
            let share = expense.amount / Double(expense.splitBetween.count)
            result[expense.paidBy, default: 0] += expense.amount
            for participantId in expense.splitBetween {
                result[participantId, default: 0] -= share
            }
        }
        return result
    }

    /// Greedy debt-simplification: matches the biggest creditor with the biggest debtor
    /// repeatedly, guaranteeing at most n-1 transactions for n people.
    static func settlements(from balances: [UUID: Double]) -> [Settlement] {
        var creditors = balances
            .filter { $0.value > 0.01 }
            .map { (id: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        var debtors = balances
            .filter { $0.value < -0.01 }
            .map { (id: $0.key, amount: $0.value) }
            .sorted { $0.amount < $1.amount }

        var result: [Settlement] = []
        var ci = 0
        var di = 0

        while ci < creditors.count && di < debtors.count {
            let amount = min(creditors[ci].amount, -debtors[di].amount)
            let rounded = (amount * 100).rounded() / 100

            if rounded > 0.005 {
                result.append(Settlement(from: debtors[di].id, to: creditors[ci].id, amount: rounded))
            }

            creditors[ci].amount -= amount
            debtors[di].amount += amount

            if creditors[ci].amount < 0.01 { ci += 1 }
            if -debtors[di].amount < 0.01 { di += 1 }
        }

        return result
    }

    /// For `participantId`, returns how much each other participant owes them (positive)
    /// or is owed by them (negative), computed directly from expense participation —
    /// not routed through the minimized settlement graph, so it reflects the real
    /// person-to-person relationship rather than an optimized third-party payment.
    static func pairwiseNet(for participantId: UUID, in trip: Trip) -> [UUID: Double] {
        var net: [UUID: Double] = [:]
        for expense in trip.expenses {
            guard !expense.splitBetween.isEmpty else { continue }
            let share = expense.amount / Double(expense.splitBetween.count)
            if expense.paidBy == participantId {
                for otherId in expense.splitBetween where otherId != participantId {
                    net[otherId, default: 0] += share
                }
            } else if expense.splitBetween.contains(participantId) {
                net[expense.paidBy, default: 0] -= share
            }
        }
        return net
    }

    /// Every expense `participantId` is involved in (as payer and/or in the split),
    /// with their net effect from that single expense — positive means they're owed
    /// net from it, negative means they owe net into it.
    static func expenseBreakdown(for participantId: UUID, in trip: Trip) -> [(expense: Expense, netEffect: Double)] {
        trip.expenses
            .compactMap { expense -> (expense: Expense, netEffect: Double)? in
                let isPayer = expense.paidBy == participantId
                let isSplit = expense.splitBetween.contains(participantId)
                guard isPayer || isSplit else { return nil }
                let share = isSplit ? expense.sharePerPerson : 0
                let paid = isPayer ? expense.amount : 0
                return (expense: expense, netEffect: paid - share)
            }
            .sorted { $0.expense.date > $1.expense.date }
    }
}
