//
//  TripStore.swift
//  NAGRUZKA
//

import Foundation
import Observation

@Observable
final class TripStore {
    var tripName: String = "My Tripppp"
    var status: TripStatus = .active
    var participants: [Participant] = []
    var expenses: [Expense] = []

    func addParticipant(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        participants.append(Participant(name: trimmed))
    }

    func removeParticipant(_ participant: Participant) {
        participants.removeAll { $0.id == participant.id }
    }

    func addEqualSplitExpense(
        description: String,
        amount: Double,
        category: ExpenseCategory,
        paidBy: Participant,
        splitAmong: [Participant]
    ) {
        guard amount > 0, !splitAmong.isEmpty else { return }
        let paid = [PaidByEntry(participantId: paidBy.id, amountPaid: amount)]
        let split = equalSplit(amount: amount, among: splitAmong)
        let expense = Expense(category: category, description: description, amount: amount, paidBy: paid, splitBetween: split)
        expenses.append(expense)
    }

    func removeExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }

    // Leftover cents from an uneven split go to the first person(s) in the list,
    // so the split always sums to exactly `amount`.
    private func equalSplit(amount: Double, among people: [Participant]) -> [SplitEntry] {
        let totalCents = Int((amount * 100).rounded())
        let baseShare = totalCents / people.count
        var remainder = totalCents % people.count
        return people.map { person in
            var share = baseShare
            if remainder > 0 {
                share += 1
                remainder -= 1
            }
            return SplitEntry(participantId: person.id, amountOwed: Double(share) / 100)
        }
    }

    var balances: [UUID: Double] {
        var result: [UUID: Double] = [:]
        for participant in participants {
            result[participant.id] = 0
        }
        for expense in expenses {
            for entry in expense.paidBy {
                result[entry.participantId, default: 0] += entry.amountPaid
            }
            for entry in expense.splitBetween {
                result[entry.participantId, default: 0] -= entry.amountOwed
            }
        }
        return result
    }

    var settlements: [Settlement] {
        var creditors: [(id: UUID, amount: Double)] = []
        var debtors: [(id: UUID, amount: Double)] = []

        for (id, balance) in balances {
            let rounded = (balance * 100).rounded() / 100
            if rounded > 0.005 {
                creditors.append((id, rounded))
            } else if rounded < -0.005 {
                debtors.append((id, -rounded))
            }
        }

        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }

        var result: [Settlement] = []
        var i = 0
        var j = 0

        while i < debtors.count && j < creditors.count {
            let amount = min(debtors[i].amount, creditors[j].amount)

            if amount > 0.005 {
                result.append(Settlement(fromId: debtors[i].id, toId: creditors[j].id, amount: amount))
            }

            debtors[i].amount -= amount
            creditors[j].amount -= amount

            if debtors[i].amount <= 0.005 { i += 1 }
            if creditors[j].amount <= 0.005 { j += 1 }
        }

        return result
    }

    func name(for id: UUID) -> String {
        participants.first { $0.id == id }?.name ?? "Unknown"
    }
}
