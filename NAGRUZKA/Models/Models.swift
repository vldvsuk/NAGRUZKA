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

struct Expense: Identifiable, Codable, Hashable {
    let id: UUID
    var description: String
    var category: ExpenseCategory
    var amount: Double
    var paidBy: UUID
    var splitBetween: [UUID]
    var date: Date

    init(
        id: UUID = UUID(),
        description: String,
        category: ExpenseCategory,
        amount: Double,
        paidBy: UUID,
        splitBetween: [UUID],
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

    var sharePerPerson: Double {
        guard !splitBetween.isEmpty else { return 0 }
        return amount / Double(splitBetween.count)
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

    var coverColor: Color { Color(hex: coverColorHex) }
    var totalSpent: Double { expenses.reduce(0) { $0 + $1.amount } }
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

struct Settlement: Identifiable, Hashable {
    var id: String { "\(from)-\(to)" }
    let from: UUID
    let to: UUID
    let amount: Double
}
