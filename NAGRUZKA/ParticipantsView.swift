//
//  ParticipantsView.swift
//  NAGRUZKA
//

import SwiftUI

struct ParticipantsView: View {
    @Environment(TripStore.self) private var store
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add participant", text: $newName)
                            .onSubmit(addParticipant)
                        Button("Add", action: addParticipant)
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section("Participants (\(store.participants.count))") {
                    if store.participants.isEmpty {
                        Text("No one has joined yet")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.participants) { participant in
                        Text(participant.name)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.removeParticipant(store.participants[index])
                        }
                    }
                }
            }
            .navigationTitle(store.tripName)
        }
    }

    private func addParticipant() {
        store.addParticipant(name: newName)
        newName = ""
    }
}

#Preview {
    ParticipantsView()
        .environment(TripStore())
}
