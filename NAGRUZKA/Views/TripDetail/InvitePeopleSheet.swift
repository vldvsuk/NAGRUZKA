//
//  InvitePeopleSheet.swift
//  NAGRUZKA
//

import SwiftUI

struct InvitePeopleSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripId: UUID

    @State private var selectedFriendIds: Set<UUID> = []
    private let inviteCode = String(UUID().uuidString.prefix(8)).lowercased()

    private var trip: Trip? { store.trip(id: tripId) }
    private var existingIds: Set<UUID> { Set(trip?.participants.map(\.id) ?? []) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InvitePeopleSection(selectedFriendIds: $selectedFriendIds, excludedIds: existingIds, inviteCode: inviteCode)

                    if let trip, !trip.participants.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ALREADY IN THIS TRIP")
                                .font(.system(size: 9, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(AppTheme.foreground.opacity(0.35))
                            VStack(spacing: 0) {
                                ForEach(Array(trip.participants.enumerated()), id: \.element.id) { index, p in
                                    if index > 0 { Divider().padding(.leading, 56) }
                                    HStack(spacing: 12) {
                                        AvatarView(participant: p, size: 32)
                                        Text(p.name).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.foreground)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                            }
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle("Invite people")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        for id in selectedFriendIds {
                            if let friend = store.friends.first(where: { $0.id == id }) {
                                store.addFriendToTrip(friend, to: tripId)
                            }
                        }
                        dismiss()
                    }
                    .disabled(selectedFriendIds.isEmpty)
                }
            }
        }
    }
}

#Preview {
    let store = AppStore()
    return InvitePeopleSheet(tripId: store.trips[0].id)
        .environment(store)
}
