//
//  TripCardView.swift
//  NAGRUZKA
//

import SwiftUI

struct TripCardView: View {
    let trip: Trip
    let myBalance: Double

    private var isPositive: Bool { myBalance > 0.01 }
    private var isNegative: Bool { myBalance < -0.01 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(trip.coverColor)
                .frame(height: 6)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: trip.status == .ended ? "lock.fill" : "globe")
                                .font(.system(size: 9))
                            Text(trip.status == .ended ? "ARCHIVED" : "ACTIVE")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .tracking(1)
                        }
                        .foregroundStyle(trip.status == .ended ? AppTheme.mutedForeground : AppTheme.positive)

                        Text(trip.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.foreground)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "mappin.and.ellipse").font(.system(size: 9))
                                Text(trip.destination)
                            }
                            Text("·")
                            HStack(spacing: 3) {
                                Image(systemName: "calendar").font(.system(size: 9))
                                Text(trip.dateRange)
                            }
                        }
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppTheme.mutedForeground)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("€\(Formatting.money(trip.totalSpent))")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.foreground)
                        if isPositive || isNegative {
                            Text("\(isPositive ? "+" : "−")€\(Formatting.money(abs(myBalance))) you")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(isPositive ? AppTheme.positive : AppTheme.negative)
                        }
                    }
                }

                Divider()

                HStack {
                    HStack(spacing: -6) {
                        ForEach(trip.participants.prefix(5)) { p in
                            AvatarView(participant: p, size: 22)
                                .overlay(Circle().stroke(AppTheme.card, lineWidth: 1.5))
                        }
                        if trip.participants.count > 5 {
                            Circle()
                                .fill(AppTheme.chip)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Text("+\(trip.participants.count - 5)")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundStyle(AppTheme.mutedForeground)
                                )
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(trip.expenses.count) expenses")
                            .font(.system(size: 10, design: .monospaced))
                        Image(systemName: "arrow.right").font(.system(size: 10))
                    }
                    .foregroundStyle(AppTheme.mutedForeground)
                }
            }
            .padding(16)
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
    }
}

#Preview {
    let trip = Trip(
        id: UUID(), name: "Prague Weekend", destination: "Czech Republic", dateRange: "14–16 Mar 2024",
        currency: "EUR", status: .active,
        participants: [
            Participant(name: "Vlad", colorHex: "4F46E5"),
            Participant(name: "Dima", colorHex: "D97706"),
        ],
        expenses: [
            Expense(description: "Hotel", category: .accommodation, amount: 320, paidBy: UUID(), splitBetween: [SplitShare(participantId: UUID(), amountOwed: 320)]),
        ],
        coverColorHex: "4F46E5"
    )
    return TripCardView(trip: trip, myBalance: 42.5)
        .padding()
}
