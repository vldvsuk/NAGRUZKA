//
//  Models.swift
//  NAGRUZKA
//

import Foundation

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food = "Food"
    case transport = "Transport"
    case flights = "Flights"
    case accommodation = "Accommodation"
    case activities = "Activities"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .flights: return "airplane"
        case .accommodation: return "bed.double.fill"
        case .activities: return "figure.hiking"
        case .other: return "ellipsis.circle"
        }
    }
}

struct Participant: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

struct PaidByEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var participantId: UUID
    var amountPaid: Double
}

struct SplitEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var participantId: UUID
    var amountOwed: Double
}

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var category: ExpenseCategory
    var description: String
    var amount: Double
    var paidBy: [PaidByEntry]
    var splitBetween: [SplitEntry]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        category: ExpenseCategory,
        description: String,
        amount: Double,
        paidBy: [PaidByEntry],
        splitBetween: [SplitEntry],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.description = description
        self.amount = amount
        self.paidBy = paidBy
        self.splitBetween = splitBetween
        self.createdAt = createdAt
    }
}

struct Settlement: Identifiable {
    let id = UUID()
    let fromId: UUID
    let toId: UUID
    let amount: Double
}

enum TripStatus: String, Codable {
    case active
    case ended
}
