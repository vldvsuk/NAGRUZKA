//
//  AvatarView.swift
//  NAGRUZKA
//

import SwiftUI

struct AvatarView: View {
    let participant: Participant
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(participant.color)
            .frame(width: size, height: size)
            .overlay(
                Text(participant.name.prefix(1))
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

#Preview {
    AvatarView(participant: Participant(name: "Vlad", colorHex: "4F46E5"), size: 48)
}
