//
//  Models.swift
//  NAGRUZKA
//

import SwiftUI

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case accommodation = "Accommodation"
    case food = "Food"
    case transport = "Transport"
    case flights = "Flights"
    case activities = "Activities"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .accommodation: return "building.2.fill"
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .flights: return "airplane"
        case .activities: return "ticket.fill"
        case .other: return "shippingbox.fill"
        }
    }

    var color: Color {
        switch self {
        case .accommodation: return Color(hex: "6366F1")
        case .food: return Color(hex: "F59E0B")
        case .transport: return Color(hex: "10B981")
        case .flights: return Color(hex: "3B82F6")
        case .activities: return Color(hex: "EC4899")
        case .other: return Color(hex: "6B7280")
        }
    }
}

enum TripStatus: String, Codable, Hashable {
    case active
    case ended
}

struct Participant: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    var color: Color { Color(hex: colorHex) }
}

/// One person's exact owed amount for an expense — lets a split be uneven
/// (custom amounts) instead of always dividing the total equally.
struct SplitShare: Codable, Hashable {
    var participantId: UUID
    var amountOwed: Double
}

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var description: String
    var category: ExpenseCategory
    var amount: Double
    var paidBy: UUID
    var splitBetween: [SplitShare]
    var date: Date

    init(
        id: UUID = UUID(),
        description: String,
        category: ExpenseCategory,
        amount: Double,
        paidBy: UUID,
        splitBetween: [SplitShare],
        date: Date = Date()
    ) {
        self.id = id
        self.description = description
        self.category = category
        self.amount = amount
        self.paidBy = paidBy
        self.splitBetween = splitBetween
        self.date = date
    }

    func amountOwed(by participantId: UUID) -> Double? {
        splitBetween.first { $0.participantId == participantId }?.amountOwed
    }

    /// The common per-person amount if everyone's share is equal, else nil (custom split).
    var equalShareAmount: Double? {
        guard let first = splitBetween.first?.amountOwed else { return nil }
        return splitBetween.allSatisfy { abs($0.amountOwed - first) < 0.01 } ? first : nil
    }
}

extension Array where Element == UUID {
    /// Splits `amount` evenly in cents across these participant ids, handing any
    /// leftover 1-2 cents to the first ids so the shares always sum to exactly `amount`.
    func equalShares(of amount: Double) -> [SplitShare] {
        guard !isEmpty else { return [] }
        let totalCents = Int((amount * 100).rounded())
        let base = totalCents / count
        var remainder = totalCents % count
        return map { id in
            var cents = base
            if remainder > 0 {
                cents += 1
                remainder -= 1
            }
            return SplitShare(participantId: id, amountOwed: Double(cents) / 100)
        }
    }
}

/// A real payment someone made to settle part of what they owed — recorded when a
/// Settle Up entry is marked as paid. Reduces balances going forward without
/// touching the underlying expenses, so nothing is lost or double-counted.
struct RecordedSettlement: Identifiable, Codable, Hashable {
    let id: UUID
    var from: UUID
    var to: UUID
    var amount: Double
    var date: Date

    init(id: UUID = UUID(), from: UUID, to: UUID, amount: Double, date: Date = Date()) {
        self.id = id
        self.from = from
        self.to = to
        self.amount = amount
        self.date = date
    }
}

struct Trip: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var destination: String
    var dateRange: String
    var currency: String
    var status: TripStatus
    var participants: [Participant]
    var expenses: [Expense]
    var coverColorHex: String
    var recordedSettlements: [RecordedSettlement] = []

    var coverColor: Color { Color(hex: coverColorHex) }
    var totalSpent: Double { expenses.reduce(0) { $0 + $1.amount } }

    /// `participantId`'s personal share of the trip's costs — their own portion of every
    /// expense they're split into, regardless of who fronted the money. If they paid €500
    /// for a dinner split 5 ways, this counts their €100 share, not the €500 they covered.
    func personalSpend(by participantId: UUID) -> Double {
        expenses.reduce(0) { $0 + ($1.amountOwed(by: participantId) ?? 0) }
    }
}

extension Trip {
    static var placeholder: Trip {
        Trip(
            id: UUID(),
            name: "",
            destination: "",
            dateRange: "",
            currency: "EUR",
            status: .active,
            participants: [],
            expenses: [],
            coverColorHex: "141410"
        )
    }
}

/// One person-to-person debt in the Settle Up list. Stays visible after being paid
/// (rather than disappearing) so there's a record of it and it can be undone.
struct SettlementLedgerEntry: Identifiable, Hashable {
    var id: String { "\(from)-\(to)" }
    let from: UUID
    let to: UUID
    let owedAmount: Double
    let paidAmount: Double

    var remaining: Double { max(0, owedAmount - paidAmount) }
    var isSettled: Bool { remaining < 0.01 }
}
