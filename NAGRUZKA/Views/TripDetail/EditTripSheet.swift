//
//  EditTripSheet.swift
//  NAGRUZKA
//
//  Rename the trip, change its destination, and manage who's in it —
//  add people from friends/invite link, or remove existing participants.
//

import SwiftUI

struct EditTripSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripId: UUID

    @State private var name = ""
    @State private var destination = ""
    @State private var selectedFriendIds: Set<UUID> = []
    @State private var inviteCode = String(UUID().uuidString.prefix(8)).lowercased()
    @State private var participantPendingRemoval: Participant?

    private var trip: Trip? { store.trip(id: tripId) }
    private var existingIds: Set<UUID> { Set(trip?.participants.map(\.id) ?? []) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nameField
                    destinationField
                    participantsSection
                    addParticipantsSection
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle("Trip settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let trip {
                    name = trip.name
                    destination = trip.destination
                }
            }
            .confirmationOverlay(
                isPresented: Binding(
                    get: { participantPendingRemoval != nil },
                    set: { if !$0 { participantPendingRemoval = nil } }
                ),
                icon: "person.fill.xmark",
                iconColor: AppTheme.negative,
                title: "Remove \(participantPendingRemoval?.name ?? "this person")?",
                message: participantRemovalMessage,
                confirmLabel: "Remove",
                isDestructive: true
            ) {
                if let p = participantPendingRemoval {
                    store.removeParticipant(p.id, from: tripId)
                }
                participantPendingRemoval = nil
            }
        }
    }

    private var participantRemovalMessage: String {
        guard let p = participantPendingRemoval, let trip else { return "" }
        let count = expenseCount(for: p.id, in: trip)
        return count > 0
            ? "\(p.name) is part of \(count) expense\(count == 1 ? "" : "s"). Those expenses will stay, just without them attached."
            : "They can be added back later from Invite."
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TRIP NAME").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            TextField("Trip name", text: $name).font(.system(size: 13))
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DESTINATION").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            TextField("Destination", text: $destination).font(.system(size: 13))
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PARTICIPANTS (\(trip?.participants.count ?? 0))")
                .font(.system(size: 9, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            VStack(spacing: 0) {
                ForEach(Array((trip?.participants ?? []).enumerated()), id: \.element.id) { index, p in
                    if index > 0 { Divider().padding(.leading, 60) }
                    participantRow(p)
                }
            }
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
        }
    }

    private func participantRow(_ p: Participant) -> some View {
        let isMe = p.id == AppStore.currentUserId
        let count = trip.map { expenseCount(for: p.id, in: $0) } ?? 0

        return HStack(spacing: 12) {
            AvatarView(participant: p, size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(p.name).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.foreground)
                if count > 0 {
                    Text("In \(count) expense\(count == 1 ? "" : "s")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppTheme.mutedForeground)
                }
            }
            Spacer()
            if isMe {
                Text("YOU")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.mutedForeground)
            } else {
                Button {
                    participantPendingRemoval = p
                } label: {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundStyle(AppTheme.negative)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var addParticipantsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD PEOPLE")
                .font(.system(size: 9, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))

            InvitePeopleSection(selectedFriendIds: $selectedFriendIds, excludedIds: existingIds, inviteCode: inviteCode)

            if !selectedFriendIds.isEmpty {
                Button {
                    for id in selectedFriendIds {
                        if let friend = store.friends.first(where: { $0.id == id }) {
                            store.addFriendToTrip(friend, to: tripId)
                        }
                    }
                    selectedFriendIds = []
                } label: {
                    Text("Add \(selectedFriendIds.count) to trip")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private func expenseCount(for participantId: UUID, in trip: Trip) -> Int {
        trip.expenses.filter { $0.paidBy == participantId || $0.amountOwed(by: participantId) != nil }.count
    }

    private func save() {
        store.updateTripDetails(tripId: tripId, name: name, destination: destination)
        dismiss()
    }
}

#Preview {
    let store = AppStore()
    return EditTripSheet(tripId: store.trips[0].id)
        .environment(store)
}
