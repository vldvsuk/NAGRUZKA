//
//  AppStore.swift
//  NAGRUZKA
//

import Foundation
import Observation

@Observable
final class AppStore {
    static let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    var trips: [Trip]

    init() {
        trips = AppStore.seedTrips()
    }

    func trip(id: UUID) -> Trip? {
        trips.first { $0.id == id }
    }

    var overallBalance: Double {
        trips.reduce(0) { sum, trip in
            let balances = BalanceCalculator.balances(for: trip)
            return sum + (balances[AppStore.currentUserId] ?? 0)
        }
    }

    @discardableResult
    func createTrip(name: String, destination: String) -> Trip {
        let coverColors = ["FF3D20", "6366F1", "10B981", "F59E0B", "EC4899", "3B82F6"]
        let me = Participant(id: AppStore.currentUserId, name: "Vlad", colorHex: "4F46E5")
        let trip = Trip(
            id: UUID(),
            name: name,
            destination: destination.isEmpty ? "Unknown" : destination,
            dateRange: Formatting.shortDate(Date()),
            currency: "EUR",
            status: .active,
            participants: [me],
            expenses: [],
            coverColorHex: coverColors[trips.count % coverColors.count]
        )
        trips.insert(trip, at: 0)
        return trip
    }

    func addParticipant(name: String, to tripId: UUID) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let colors = ["D97706", "DB2777", "059669", "0EA5E9", "7C3AED", "F59E0B"]
        let color = colors[trips[idx].participants.count % colors.count]
        trips[idx].participants.append(Participant(name: trimmed, colorHex: color))
    }

    func addExpense(
        to tripId: UUID,
        description: String,
        category: ExpenseCategory,
        amount: Double,
        paidBy: UUID,
        splitBetween: [UUID]
    ) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }), amount > 0, !splitBetween.isEmpty else { return }
        let expense = Expense(description: description, category: category, amount: amount, paidBy: paidBy, splitBetween: splitBetween)
        trips[idx].expenses.insert(expense, at: 0)
    }

    private static func seedTrips() -> [Trip] {
        let vlad = Participant(id: currentUserId, name: "Vlad", colorHex: "4F46E5")

        let sviat = Participant(name: "Sviat", colorHex: "D97706")
        let vika = Participant(name: "Vika", colorHex: "DB2777")
        let roman = Participant(name: "Roman", colorHex: "059669")
        let pragueParticipants = [vlad, sviat, vika, roman]
        let prague = Trip(
            id: UUID(),
            name: "Prague Weekend",
            destination: "Czech Republic",
            dateRange: "14–16 Mar 2024",
            currency: "EUR",
            status: .active,
            participants: pragueParticipants,
            expenses: [
                Expense(description: "Hotel Ventana", category: .accommodation, amount: 320, paidBy: vlad.id, splitBetween: pragueParticipants.map(\.id), date: makeDate(2024, 3, 14)),
                Expense(description: "Dinner at V Zátiší", category: .food, amount: 87, paidBy: sviat.id, splitBetween: pragueParticipants.map(\.id), date: makeDate(2024, 3, 14)),
                Expense(description: "Old Town Museum", category: .activities, amount: 48, paidBy: vika.id, splitBetween: [vlad.id, vika.id, roman.id], date: makeDate(2024, 3, 15)),
                Expense(description: "Airport transfer", category: .transport, amount: 34, paidBy: roman.id, splitBetween: pragueParticipants.map(\.id), date: makeDate(2024, 3, 15)),
                Expense(description: "Sunday brunch", category: .food, amount: 62, paidBy: vlad.id, splitBetween: pragueParticipants.map(\.id), date: makeDate(2024, 3, 16)),
            ],
            coverColorHex: "4F46E5"
        )

        let mia = Participant(name: "Mia", colorHex: "0EA5E9")
        let tom = Participant(name: "Tom", colorHex: "7C3AED")
        let lisbonParticipants = [vlad, mia, tom]
        let lisbon = Trip(
            id: UUID(),
            name: "Lisbon Summer",
            destination: "Portugal",
            dateRange: "1–7 Jun 2024",
            currency: "EUR",
            status: .active,
            participants: lisbonParticipants,
            expenses: [
                Expense(description: "Airbnb Alfama", category: .accommodation, amount: 480, paidBy: vlad.id, splitBetween: lisbonParticipants.map(\.id), date: makeDate(2024, 6, 1)),
                Expense(description: "TAP flights (3x)", category: .flights, amount: 390, paidBy: mia.id, splitBetween: lisbonParticipants.map(\.id), date: makeDate(2024, 5, 28)),
                Expense(description: "Tasca do Chico", category: .food, amount: 67, paidBy: tom.id, splitBetween: lisbonParticipants.map(\.id), date: makeDate(2024, 6, 2)),
            ],
            coverColorHex: "F59E0B"
        )

        let sara = Participant(name: "Sara", colorHex: "EC4899")
        let felix = Participant(name: "Felix", colorHex: "10B981")
        let noah = Participant(name: "Noah", colorHex: "F59E0B")
        let lena = Participant(name: "Lena", colorHex: "6366F1")
        let berlinParticipants = [vlad, sara, felix, noah, lena]
        let berlin = Trip(
            id: UUID(),
            name: "Berlin NYE",
            destination: "Germany",
            dateRange: "30 Dec – 2 Jan",
            currency: "EUR",
            status: .ended,
            participants: berlinParticipants,
            expenses: [
                Expense(description: "Hostel Mitte", category: .accommodation, amount: 640, paidBy: vlad.id, splitBetween: berlinParticipants.map(\.id), date: makeDate(2023, 12, 30)),
                Expense(description: "NYE party tickets", category: .activities, amount: 250, paidBy: felix.id, splitBetween: berlinParticipants.map(\.id), date: makeDate(2023, 12, 31)),
                Expense(description: "Supermarket run", category: .food, amount: 89, paidBy: sara.id, splitBetween: berlinParticipants.map(\.id), date: makeDate(2023, 12, 31)),
            ],
            coverColorHex: "141410"
        )

        return [prague, lisbon, berlin]
    }

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
