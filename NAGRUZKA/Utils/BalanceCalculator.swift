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
            result[expense.paidBy, default: 0] += expense.amount
            for share in expense.splitBetween {
                result[share.participantId, default: 0] -= share.amountOwed
            }
        }
        for settlement in trip.recordedSettlements {
            result[settlement.from, default: 0] += settlement.amount
            result[settlement.to, default: 0] -= settlement.amount
        }
        return result
    }

    /// For `participantId`, returns how much each other participant owes them (positive)
    /// or is owed by them (negative), computed directly from expense participation —
    /// not routed through a minimized settlement graph, so it reflects the real
    /// person-to-person relationship rather than an optimized third-party payment.
    /// Recorded payments (marked "paid" in Settle Up) reduce these amounts.
    static func pairwiseNet(for participantId: UUID, in trip: Trip) -> [UUID: Double] {
        var net: [UUID: Double] = [:]
        for expense in trip.expenses {
            if expense.paidBy == participantId {
                for share in expense.splitBetween where share.participantId != participantId {
                    net[share.participantId, default: 0] += share.amountOwed
                }
            } else if let mine = expense.amountOwed(by: participantId) {
                net[expense.paidBy, default: 0] -= mine
            }
        }
        for settlement in trip.recordedSettlements {
            if settlement.from == participantId {
                net[settlement.to, default: 0] += settlement.amount
            } else if settlement.to == participantId {
                net[settlement.from, default: 0] -= settlement.amount
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
                let mine = expense.amountOwed(by: participantId)
                guard isPayer || mine != nil else { return nil }
                let paid = isPayer ? expense.amount : 0
                return (expense: expense, netEffect: paid - (mine ?? 0))
            }
            .sorted { $0.expense.date > $1.expense.date }
    }

    /// The full, un-minimized ledger: every pair of people with a nonzero direct debt
    /// between them (net of anything they owe each other in the opposite direction),
    /// alongside how much of that debt has actually been paid. Unlike a minimized
    /// settlement (fewest transactions via net balance), this shows every real
    /// person-to-person debt — e.g. "Vika owes Sviat €21.75" even though Sviat
    /// separately owes someone else overall. Entries stay in the list once paid
    /// (marked settled) instead of disappearing, so paying can be undone.
    static func settlementLedger(in trip: Trip) -> [SettlementLedgerEntry] {
        var owes: [UUID: [UUID: Double]] = [:]
        for expense in trip.expenses {
            for share in expense.splitBetween where share.participantId != expense.paidBy {
                owes[share.participantId, default: [:]][expense.paidBy, default: 0] += share.amountOwed
            }
        }

        var entries: [SettlementLedgerEntry] = []
        var seenPairs = Set<Set<UUID>>()

        for (a, targets) in owes {
            for b in targets.keys {
                let pairKey: Set<UUID> = [a, b]
                guard !seenPairs.contains(pairKey) else { continue }
                seenPairs.insert(pairKey)

                let aOwesB = owes[a]?[b] ?? 0
                let bOwesA = owes[b]?[a] ?? 0
                let net = aOwesB - bOwesA
                guard abs(net) > 0.01 else { continue }

                let from = net > 0 ? a : b
                let to = net > 0 ? b : a
                let owedAmount = (abs(net) * 100).rounded() / 100
                let paidAmount = trip.recordedSettlements
                    .filter { $0.from == from && $0.to == to }
                    .reduce(0) { $0 + $1.amount }

                entries.append(SettlementLedgerEntry(from: from, to: to, owedAmount: owedAmount, paidAmount: paidAmount))
            }
        }

        return entries.sorted { $0.owedAmount > $1.owedAmount }
    }
}
