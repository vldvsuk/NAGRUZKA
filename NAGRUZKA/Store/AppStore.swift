//
//  AppStore.swift
//  NAGRUZKA
//

import Foundation
import Observation

@Observable
final class AppStore {
    static let currentUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private static let sviatId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private static let vikaId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    private static let romanId = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    private static let miaId = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    private static let tomId = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    private static let saraId = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
    private static let felixId = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    private static let noahId = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
    private static let lenaId = UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!

    var trips: [Trip]

    /// People you've added before (via a past invite link or manual add), so they can
    /// be picked again for a new trip instead of re-entering their name.
    var friends: [Participant]

    init() {
        friends = AppStore.seedFriends()
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

    /// `participantId`'s personal share of costs across every active (non-archived) trip —
    /// their own portion of each expense they're split into, regardless of who fronted
    /// the money. Archived trips don't count toward this total.
    func personalSpend(by participantId: UUID) -> Double {
        trips
            .filter { $0.status == .active }
            .reduce(0) { $0 + $1.personalSpend(by: participantId) }
    }

    /// Archives an active trip, or reopens an archived one.
    func toggleTripStatus(tripId: UUID) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].status = trips[idx].status == .active ? .ended : .active
    }

    /// Records a real payment for a Settle Up entry marked as paid — reduces balances
    /// from here on without touching the underlying expenses. The entry stays visible,
    /// marked settled, until `removeSettlementPayments` undoes it.
    func recordSettlementPayment(tripId: UUID, from: UUID, to: UUID, amount: Double) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].recordedSettlements.append(RecordedSettlement(from: from, to: to, amount: amount))
    }

    /// Undoes every recorded payment between this pair, restoring the entry to unpaid.
    func removeSettlementPayments(tripId: UUID, from: UUID, to: UUID) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].recordedSettlements.removeAll { $0.from == from && $0.to == to }
    }

    @discardableResult
    func createTrip(name: String, destination: String, participants: [Participant] = []) -> Trip {
        let coverColors = ["FF3D20", "6366F1", "10B981", "F59E0B", "EC4899", "3B82F6"]
        let me = Participant(id: AppStore.currentUserId, name: "Vlad", colorHex: "4F46E5")
        var members = [me]
        for p in participants where !members.contains(where: { $0.id == p.id }) {
            members.append(p)
        }
        let trip = Trip(
            id: UUID(),
            name: name,
            destination: destination.isEmpty ? "Unknown" : destination,
            dateRange: Formatting.shortDate(Date()),
            currency: "EUR",
            status: .active,
            participants: members,
            expenses: [],
            coverColorHex: coverColors[trips.count % coverColors.count]
        )
        trips.insert(trip, at: 0)
        return trip
    }

    /// Adds a friend (already in `friends`) to a trip they're not yet part of.
    func addFriendToTrip(_ friend: Participant, to tripId: UUID) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        guard !trips[idx].participants.contains(where: { $0.id == friend.id }) else { return }
        trips[idx].participants.append(friend)
    }

    /// Removes a participant from a trip. Their past expenses are left untouched —
    /// they'll just show up unassigned wherever that person was referenced.
    func removeParticipant(_ participantId: UUID, from tripId: UUID) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        trips[idx].participants.removeAll { $0.id == participantId }
    }

    func updateTripDetails(tripId: UUID, name: String, destination: String) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        trips[idx].name = trimmedName
        trips[idx].destination = destination.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Unknown"
            : destination.trimmingCharacters(in: .whitespaces)
    }

    /// Registers a new friend (e.g. someone typing their name after opening an invite
    /// link) so they can be picked straight from the friends list on future trips.
    @discardableResult
    func addFriend(name: String, colorHex: String? = nil) -> Participant {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = friends.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let palette = ["D97706", "DB2777", "059669", "0EA5E9", "7C3AED", "F59E0B", "EC4899", "10B981", "6366F1"]
        let color = colorHex ?? palette[friends.count % palette.count]
        let friend = Participant(name: trimmed, colorHex: color)
        friends.append(friend)
        return friend
    }

    func addParticipant(name: String, to tripId: UUID) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }) else { return }
        let friend = addFriend(name: name)
        guard !trips[idx].participants.contains(where: { $0.id == friend.id }) else { return }
        trips[idx].participants.append(friend)
    }

    func addExpense(
        to tripId: UUID,
        description: String,
        category: ExpenseCategory,
        amount: Double,
        paidBy: UUID,
        splitBetween: [SplitShare]
    ) {
        guard let idx = trips.firstIndex(where: { $0.id == tripId }), amount > 0, !splitBetween.isEmpty else { return }
        let expense = Expense(description: description, category: category, amount: amount, paidBy: paidBy, splitBetween: splitBetween)
        trips[idx].expenses.insert(expense, at: 0)
    }

    private static func seedFriends() -> [Participant] {
        [
            Participant(id: sviatId, name: "Sviat", colorHex: "D97706"),
            Participant(id: vikaId, name: "Vika", colorHex: "DB2777"),
            Participant(id: romanId, name: "Roman", colorHex: "059669"),
            Participant(id: miaId, name: "Mia", colorHex: "0EA5E9"),
            Participant(id: tomId, name: "Tom", colorHex: "7C3AED"),
            Participant(id: saraId, name: "Sara", colorHex: "EC4899"),
            Participant(id: felixId, name: "Felix", colorHex: "10B981"),
            Participant(id: noahId, name: "Noah", colorHex: "F59E0B"),
            Participant(id: lenaId, name: "Lena", colorHex: "6366F1"),
        ]
    }

    private static func seedTrips() -> [Trip] {
        let vlad = Participant(id: currentUserId, name: "Vlad", colorHex: "4F46E5")
        let byName = Dictionary(uniqueKeysWithValues: seedFriends().map { ($0.name, $0) })

        let sviat = byName["Sviat"]!
        let vika = byName["Vika"]!
        let roman = byName["Roman"]!
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
                Expense(description: "Hotel Ventana", category: .accommodation, amount: 320, paidBy: vlad.id, splitBetween: pragueParticipants.map(\.id).equalShares(of: 320), date: makeDate(2024, 3, 14)),
                Expense(description: "Dinner at V Zátiší", category: .food, amount: 87, paidBy: sviat.id, splitBetween: pragueParticipants.map(\.id).equalShares(of: 87), date: makeDate(2024, 3, 14)),
                Expense(description: "Old Town Museum", category: .activities, amount: 48, paidBy: vika.id, splitBetween: [vlad.id, vika.id, roman.id].equalShares(of: 48), date: makeDate(2024, 3, 15)),
                Expense(description: "Airport transfer", category: .transport, amount: 34, paidBy: roman.id, splitBetween: pragueParticipants.map(\.id).equalShares(of: 34), date: makeDate(2024, 3, 15)),
                Expense(description: "Sunday brunch", category: .food, amount: 62, paidBy: vlad.id, splitBetween: pragueParticipants.map(\.id).equalShares(of: 62), date: makeDate(2024, 3, 16)),
            ],
            coverColorHex: "4F46E5"
        )

        let mia = byName["Mia"]!
        let tom = byName["Tom"]!
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
                Expense(description: "Airbnb Alfama", category: .accommodation, amount: 480, paidBy: vlad.id, splitBetween: lisbonParticipants.map(\.id).equalShares(of: 480), date: makeDate(2024, 6, 1)),
                Expense(description: "TAP flights (3x)", category: .flights, amount: 390, paidBy: mia.id, splitBetween: lisbonParticipants.map(\.id).equalShares(of: 390), date: makeDate(2024, 5, 28)),
                Expense(description: "Tasca do Chico", category: .food, amount: 67, paidBy: tom.id, splitBetween: lisbonParticipants.map(\.id).equalShares(of: 67), date: makeDate(2024, 6, 2)),
            ],
            coverColorHex: "F59E0B"
        )

        let sara = byName["Sara"]!
        let felix = byName["Felix"]!
        let noah = byName["Noah"]!
        let lena = byName["Lena"]!
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
                Expense(description: "Hostel Mitte", category: .accommodation, amount: 640, paidBy: vlad.id, splitBetween: berlinParticipants.map(\.id).equalShares(of: 640), date: makeDate(2023, 12, 30)),
                Expense(description: "NYE party tickets", category: .activities, amount: 250, paidBy: felix.id, splitBetween: berlinParticipants.map(\.id).equalShares(of: 250), date: makeDate(2023, 12, 31)),
                Expense(description: "Supermarket run", category: .food, amount: 89, paidBy: sara.id, splitBetween: berlinParticipants.map(\.id).equalShares(of: 89), date: makeDate(2023, 12, 31)),
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
