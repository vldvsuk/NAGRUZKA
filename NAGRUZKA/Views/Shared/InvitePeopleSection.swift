//
//  InvitePeopleSection.swift
//  NAGRUZKA
//
//  Reusable "add people" block: a mock invite link, a picker over your
//  saved friends, and a field to add someone new (who gets remembered
//  as a friend for next time). Not backed by a real invite/join flow yet.
//

import SwiftUI
import UIKit

struct InvitePeopleSection: View {
    @Environment(AppStore.self) private var store
    @Binding var selectedFriendIds: Set<UUID>
    var excludedIds: Set<UUID> = []
    let inviteCode: String

    @State private var newFriendName = ""
    @State private var didCopyLink = false

    private var link: String { "nagruzka.app/join/\(inviteCode)" }
    private var availableFriends: [Participant] {
        store.friends.filter { !excludedIds.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            inviteLinkCard
            if !availableFriends.isEmpty {
                friendsPicker
            }
            addNewFriendField
        }
    }

    private var inviteLinkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INVITE LINK")
                .font(.system(size: 9, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))

            HStack(spacing: 8) {
                Image(systemName: "link").font(.system(size: 12)).foregroundStyle(AppTheme.mutedForeground)
                Text(link)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.foreground)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = "https://\(link)"
                    didCopyLink = true
                } label: {
                    Label(didCopyLink ? "Copied" : "Copy", systemImage: didCopyLink ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(didCopyLink ? AppTheme.positive : AppTheme.foreground)

                ShareLink(item: "https://\(link)") {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
            }

            Text("Anyone who opens this link can join by entering their name — no account needed.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(AppTheme.foreground.opacity(0.3))
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    private var friendsPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FROM YOUR FRIENDS")
                .font(.system(size: 9, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableFriends) { friend in
                        let selected = selectedFriendIds.contains(friend.id)
                        Button {
                            if selected { selectedFriendIds.remove(friend.id) } else { selectedFriendIds.insert(friend.id) }
                        } label: {
                            VStack(spacing: 6) {
                                AvatarView(participant: friend, size: 40)
                                Text(friend.name).font(.system(size: 10, weight: .semibold)).lineLimit(1)
                            }
                            .frame(width: 64)
                            .padding(.vertical, 10)
                            .background(selected ? AppTheme.accent.opacity(0.1) : AppTheme.card)
                            .foregroundStyle(selected ? AppTheme.foreground : AppTheme.foreground.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? AppTheme.accent : AppTheme.border, lineWidth: 1))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var addNewFriendField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADD SOMEONE NEW")
                .font(.system(size: 9, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            HStack(spacing: 8) {
                TextField("Name", text: $newFriendName)
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                    .onSubmit(addNewFriend)
                Button(action: addNewFriend) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(newFriendName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("They'll be saved to your friends list for future trips too.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(AppTheme.foreground.opacity(0.3))
        }
    }

    private func addNewFriend() {
        let trimmed = newFriendName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let friend = store.addFriend(name: trimmed)
        selectedFriendIds.insert(friend.id)
        newFriendName = ""
    }
}

#Preview {
    @Previewable @State var selected: Set<UUID> = []
    return InvitePeopleSection(selectedFriendIds: $selected, inviteCode: "a1b2c3d4")
        .padding()
        .environment(AppStore())
}
