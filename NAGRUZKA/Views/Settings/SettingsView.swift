//
//  SettingsView.swift
//  NAGRUZKA
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("prefersDarkMode") private var prefersDarkMode = false
    @State private var notificationsEnabled = true
    @State private var currency = "EUR"
    @State private var splitMethod = "Equal"

    private let currencies = ["EUR", "USD", "GBP"]
    private let splitMethods = ["Equal", "Custom", "Shares"]

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileSection
                    preferencesSection
                    splittingSection
                    supportSection
                    signOutButton
                    Text("NAGRUZKA v1.0.0")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(AppTheme.foreground.opacity(0.2))
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(AppTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PREFERENCES")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1)
                .foregroundStyle(AppTheme.foreground.opacity(0.35))
            Text("Settings")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.foreground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    private var profileSection: some View {
        card {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color(hex: "4F46E5"))
                    .frame(width: 48, height: 48)
                    .overlay(Text("V").font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Vlad").font(.system(size: 14, weight: .bold)).foregroundStyle(AppTheme.foreground)
                    Text("vlad@example.com").font(.system(size: 11, design: .monospaced)).foregroundStyle(AppTheme.mutedForeground)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(AppTheme.foreground.opacity(0.25))
            }
            .padding(16)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Preferences")
            card {
                VStack(spacing: 0) {
                    settingRow(icon: "creditcard.fill", label: "Default currency") {
                        HStack(spacing: 6) {
                            ForEach(currencies, id: \.self) { c in
                                Button(c) { currency = c }
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(currency == c ? AppTheme.foreground : AppTheme.chip)
                                    .foregroundStyle(currency == c ? Color.white : AppTheme.foreground.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    Divider().padding(.leading, 55)
                    settingRow(icon: "bell.fill", label: "Notifications") {
                        Toggle("", isOn: $notificationsEnabled).labelsHidden().tint(AppTheme.accent)
                    }
                    Divider().padding(.leading, 55)
                    settingRow(icon: "moon.fill", label: "Dark mode") {
                        Toggle("", isOn: $prefersDarkMode).labelsHidden().tint(AppTheme.accent)
                    }
                }
            }
        }
    }

    private var splittingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Splitting")
            card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFAULT SPLIT METHOD")
                        .font(.system(size: 9, design: .monospaced))
                        .tracking(1)
                        .foregroundStyle(AppTheme.foreground.opacity(0.35))
                    HStack(spacing: 8) {
                        ForEach(splitMethods, id: \.self) { method in
                            Button(method) { splitMethod = method }
                                .font(.system(size: 11, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(splitMethod == method ? AppTheme.foreground : Color.clear)
                                .foregroundStyle(splitMethod == method ? Color.white : AppTheme.foreground.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(splitMethod == method ? Color.clear : AppTheme.border, lineWidth: 1))
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Support")
            card {
                VStack(spacing: 0) {
                    settingRow(icon: "doc.text.fill", label: "Export expenses") {
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AppTheme.foreground.opacity(0.2))
                    }
                    Divider().padding(.leading, 55)
                    settingRow(icon: "questionmark.circle.fill", label: "Help & FAQ") {
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AppTheme.foreground.opacity(0.2))
                    }
                    Divider().padding(.leading, 55)
                    settingRow(icon: "person.crop.circle.fill", label: "About NAGRUZKA") {
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(AppTheme.foreground.opacity(0.2))
                    }
                }
            }
        }
    }

    private var signOutButton: some View {
        card {
            Button {
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(AppTheme.negative.opacity(0.1)).frame(width: 28, height: 28)
                        Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 13)).foregroundStyle(AppTheme.negative)
                    }
                    Text("Sign out").font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.negative)
                    Spacer()
                }
                .padding(14)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .tracking(1)
            .foregroundStyle(AppTheme.foreground.opacity(0.35))
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border, lineWidth: 1))
    }

    private func settingRow<Trailing: View>(
        icon: String,
        label: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(AppTheme.chip).frame(width: 28, height: 28)
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(AppTheme.foreground.opacity(0.5))
            }
            Text(label).font(.system(size: 13, weight: .medium)).foregroundStyle(AppTheme.foreground)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView()
}
