//
//  ConfirmationOverlay.swift
//  NAGRUZKA
//
//  A centered, app-styled confirmation card (icon + title + message + Cancel/Confirm),
//  used in place of the plain system confirmation dialog for anything that needs a
//  "are you sure?" before acting — archiving a trip, removing a participant, etc.
//

import SwiftUI

private struct ConfirmationCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let confirmLabel: String
    let isDestructive: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.12)).frame(width: 56, height: 56)
                    Image(systemName: icon).font(.system(size: 22)).foregroundStyle(iconColor)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.foreground)
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.mutedForeground)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.chip)
                            .foregroundStyle(AppTheme.foreground)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button(action: onConfirm) {
                        Text(confirmLabel)
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isDestructive ? AppTheme.negative : AppTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
        }
    }
}

extension View {
    /// Shows `ConfirmationCard` over this view when `isPresented` is true, with a
    /// spring scale-and-fade entrance instead of the system dialog's slide-up sheet.
    func confirmationOverlay(
        isPresented: Binding<Bool>,
        icon: String,
        iconColor: Color = AppTheme.accent,
        title: String,
        message: String,
        confirmLabel: String,
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self
            .overlay {
                if isPresented.wrappedValue {
                    ConfirmationCard(
                        icon: icon,
                        iconColor: iconColor,
                        title: title,
                        message: message,
                        confirmLabel: confirmLabel,
                        isDestructive: isDestructive,
                        onConfirm: {
                            isPresented.wrappedValue = false
                            onConfirm()
                        },
                        onCancel: { isPresented.wrappedValue = false }
                    )
                    .scaleEffect(isPresented.wrappedValue ? 1 : 0.85)
                    .opacity(isPresented.wrappedValue ? 1 : 0)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isPresented.wrappedValue)
    }
}
