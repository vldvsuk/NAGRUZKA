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
}
