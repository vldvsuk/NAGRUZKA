//
//  TripsListView.swift
//  NAGRUZKA
//

import SwiftUI

struct TripsListView: View {
    @Environment(AppStore.self) private var store
    let onOpen: (UUID) -> Void

    @State private var showingNewTrip = false
    @State private var newName = ""
    @State private var newDestination = ""
    @State private var selectedFriendIds: Set<UUID> = []
    @State private var inviteCode = String(UUID().uuidString.prefix(8)).lowercased()

    private var active: [Trip] { store.trips.filter { $0.status == .active } }
    private var ended: [Trip] { store.trips.filter { $0.status == .ended } }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !active.isEmpty {
                        group(title: "Active", trips: active)
                    }
                    if !ended.isEmpty {
                        group(title: "Archived", trips: ended)
                    }
                    if store.trips.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showingNewTrip) {
            newTripSheet
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ALL TRIPS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(AppTheme.foreground.opacity(0.35))
                Text("Trips")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.foreground)
            }
            Spacer()
            Button {
                showingNewTrip = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                    Text("New trip").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private func group(title: String, trips: [Trip]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            VStack(spacing: 10) {
                ForEach(trips) { trip in
                    Button {
                        onOpen(trip.id)
                    } label: {
                        TripCardView(trip: trip, myBalance: BalanceCalculator.balances(for: trip)[AppStore.currentUserId] ?? 0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.foreground.opacity(0.06))
                    .frame(width: 56, height: 56)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.foreground.opacity(0.25))
            }
            Text("No trips yet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.foreground.opacity(0.5))
            Text("Tap \"New trip\" to get started")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(AppTheme.foreground.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 64)
    }

    private var newTripSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRIP NAME").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
                        TextField("e.g. Bali Squad Trip", text: $newName).font(.system(size: 13))
                    }
                    .padding(16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("DESTINATION").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
                        TextField("e.g. Indonesia", text: $newDestination).font(.system(size: 13))
                    }
                    .padding(16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))

                    InvitePeopleSection(selectedFriendIds: $selectedFriendIds, inviteCode: inviteCode)

                    if !selectedFriendIds.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("JOINING (\(selectedFriendIds.count))")
                                .font(.system(size: 9, design: .monospaced))
                                .tracking(1)
                                .foregroundStyle(AppTheme.foreground.opacity(0.35))
                            VStack(spacing: 0) {
                                let selected = store.friends.filter { selectedFriendIds.contains($0.id) }
                                ForEach(Array(selected.enumerated()), id: \.element.id) { index, friend in
                                    if index > 0 { Divider().padding(.leading, 56) }
                                    HStack(spacing: 12) {
                                        AvatarView(participant: friend, size: 32)
                                        Text(friend.name).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.foreground)
                                        Spacer()
                                        Button {
                                            selectedFriendIds.remove(friend.id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.mutedForeground)
                                        }
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
            .navigationTitle("New trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewTrip = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let participants = store.friends.filter { selectedFriendIds.contains($0.id) }
                        let trip = store.createTrip(
                            name: newName.trimmingCharacters(in: .whitespaces),
                            destination: newDestination.trimmingCharacters(in: .whitespaces),
                            participants: participants
                        )
                        newName = ""
                        newDestination = ""
                        selectedFriendIds = []
                        inviteCode = String(UUID().uuidString.prefix(8)).lowercased()
                        showingNewTrip = false
                        onOpen(trip.id)
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    TripsListView(onOpen: { _ in })
        .environment(AppStore())
}
