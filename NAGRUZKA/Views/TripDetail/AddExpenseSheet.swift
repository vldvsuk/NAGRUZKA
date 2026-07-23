//
//  AddExpenseSheet.swift
//  NAGRUZKA
//

import SwiftUI

struct AddExpenseSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripId: UUID

    enum SplitMode: String, CaseIterable {
        case equal = "Equally"
        case custom = "Custom amounts"
    }

    @State private var expenseDescription = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var paidBy: UUID?
    @State private var splitBetween: Set<UUID> = []
    @State private var splitMode: SplitMode = .equal
    @State private var customAmounts: [UUID: String] = [:]
    @State private var manuallyEditedIds: Set<UUID> = []

    private var trip: Trip? { store.trip(id: tripId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    amountField
                    descriptionField
                    categoryPicker
                    paidByPicker
                    splitSection
                    submitButton
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle("Add expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let trip {
                    if splitBetween.isEmpty {
                        splitBetween = Set(trip.participants.map(\.id))
                    }
                    if paidBy == nil {
                        paidBy = AppStore.currentUserId
                    }
                }
            }
        }
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AMOUNT").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            HStack(spacing: 6) {
                Text("€").font(.system(size: 26, weight: .bold, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.25))
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .onChange(of: amountText) {
                        if splitMode == .custom { redistributeRemaining() }
                    }
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DESCRIPTION (OPTIONAL)").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            TextField("What was it for?", text: $expenseDescription)
                .font(.system(size: 13))
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    // MARK: - Category (icon-badge grid, colored by category — reads correctly in both themes)

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ExpenseCategory.allCases) { cat in
                    let selected = category == cat
                    Button {
                        category = cat
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selected ? cat.color : cat.color.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(selected ? .white : cat.color)
                            }
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(selected ? cat.color : AppTheme.foreground.opacity(0.5))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selected ? cat.color.opacity(0.1) : AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? cat.color : AppTheme.border, lineWidth: selected ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var paidByPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAID BY").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            HStack(spacing: 8) {
                ForEach(trip?.participants ?? []) { p in
                    let selected = paidBy == p.id
                    Button {
                        paidBy = p.id
                    } label: {
                        VStack(spacing: 6) {
                            AvatarView(participant: p, size: 24)
                            Text(p.name).font(.system(size: 11, weight: .semibold)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? AppTheme.foreground : AppTheme.card)
                        .foregroundStyle(selected ? AppTheme.background : AppTheme.foreground.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Color.clear : AppTheme.border, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - Split

    private var splitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SPLIT BETWEEN").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))

            Picker("Split mode", selection: $splitMode) {
                ForEach(SplitMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: splitMode) { _, newMode in
                if newMode == .custom {
                    manuallyEditedIds.removeAll()
                    redistributeRemaining()
                }
            }

            HStack(spacing: 8) {
                ForEach(trip?.participants ?? []) { p in
                    let selected = splitBetween.contains(p.id)
                    Button {
                        toggleSplit(p.id)
                    } label: {
                        VStack(spacing: 6) {
                            AvatarView(participant: p, size: 24)
                            Text(p.name).font(.system(size: 11, weight: .semibold)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? AppTheme.accent.opacity(0.08) : AppTheme.card)
                        .foregroundStyle(selected ? AppTheme.foreground : AppTheme.foreground.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? AppTheme.accent : AppTheme.border, lineWidth: 1))
                    }
                }
            }

            if splitMode == .custom {
                customAmountsEditor
            } else if let amount = Double(amountText), !splitBetween.isEmpty {
                Text("€\(Formatting.money(amount / Double(splitBetween.count))) per person")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(AppTheme.foreground.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var customAmountsEditor: some View {
        VStack(spacing: 8) {
            ForEach(trip?.participants.filter { splitBetween.contains($0.id) } ?? []) { p in
                HStack(spacing: 10) {
                    AvatarView(participant: p, size: 22)
                    Text(p.name).font(.system(size: 12, weight: .medium)).foregroundStyle(AppTheme.foreground)
                    Spacer()
                    Text("€").font(.system(size: 12, design: .monospaced)).foregroundStyle(AppTheme.foreground.opacity(0.3))
                    TextField("0.00", text: customAmountBinding(for: p.id))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .frame(width: 64)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
            }

            HStack {
                Spacer()
                Text(remainingLabel)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isBalanced ? AppTheme.positive : AppTheme.negative)
            }
        }
    }

    private func customAmountBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { customAmounts[id] ?? "" },
            set: { newValue in
                manuallyEditedIds.insert(id)
                customAmounts[id] = newValue
                clampAndRedistribute(editedId: id)
            }
        )
    }

    private var customTotal: Double {
        splitBetween.reduce(0) { $0 + (Double(customAmounts[$1] ?? "") ?? 0) }
    }

    private var isBalanced: Bool {
        guard let amount = Double(amountText) else { return false }
        return abs(customTotal - amount) < 0.01
    }

    private var remainingLabel: String {
        guard let amount = Double(amountText) else { return "" }
        let diff = amount - customTotal
        if abs(diff) < 0.01 { return "Balanced ✓" }
        return diff > 0 ? "€\(Formatting.money(diff)) left to assign" : "€\(Formatting.money(abs(diff))) over the total"
    }

    private func toggleSplit(_ id: UUID) {
        if splitBetween.contains(id) {
            splitBetween.remove(id)
            customAmounts.removeValue(forKey: id)
            manuallyEditedIds.remove(id)
        } else {
            splitBetween.insert(id)
        }
        if splitMode == .custom { redistributeRemaining() }
    }

    /// Keeps the sum of manually-typed amounts from ever exceeding the total, then
    /// spreads whatever's left evenly across the people nobody has typed a value for yet —
    /// so typing 30 for one person on a €50 expense with 2 others left immediately
    /// shows €10 / €10 for the rest, no extra taps needed.
    private func clampAndRedistribute(editedId: UUID) {
        guard let total = Double(amountText) else { return }

        let otherEditedSum = manuallyEditedIds
            .filter { $0 != editedId }
            .reduce(0) { $0 + (Double(customAmounts[$1] ?? "") ?? 0) }
        let thisValue = Double(customAmounts[editedId] ?? "") ?? 0
        let maxAllowed = max(0, total - otherEditedSum)
        if thisValue > maxAllowed {
            customAmounts[editedId] = Formatting.money(maxAllowed)
        }

        redistributeRemaining()
    }

    private func redistributeRemaining() {
        guard let total = Double(amountText) else { return }
        let unedited = splitBetween.subtracting(manuallyEditedIds)
        guard !unedited.isEmpty else { return }

        let editedSum = manuallyEditedIds.reduce(0) { $0 + (Double(customAmounts[$1] ?? "") ?? 0) }
        let remaining = max(0, total - editedSum)
        for share in Array(unedited).equalShares(of: remaining) {
            customAmounts[share.participantId] = Formatting.money(share.amountOwed)
        }
    }

    // MARK: - Submit

    private var canSubmit: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        guard paidBy != nil, !splitBetween.isEmpty else { return false }
        return splitMode == .custom ? isBalanced : true
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Text("Add expense")
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSubmit ? AppTheme.accent : AppTheme.foreground.opacity(0.1))
                .foregroundStyle(canSubmit ? Color.white : AppTheme.foreground.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!canSubmit)
    }

    private func submit() {
        guard let amount = Double(amountText), let paidBy else { return }

        let shares: [SplitShare]
        if splitMode == .custom {
            shares = splitBetween.compactMap { id in
                guard let value = Double(customAmounts[id] ?? "") else { return nil }
                return SplitShare(participantId: id, amountOwed: value)
            }
        } else {
            shares = Array(splitBetween).equalShares(of: amount)
        }

        let trimmedDescription = expenseDescription.trimmingCharacters(in: .whitespaces)
        store.addExpense(
            to: tripId,
            description: trimmedDescription.isEmpty ? category.rawValue : trimmedDescription,
            category: category,
            amount: amount,
            paidBy: paidBy,
            splitBetween: shares
        )
        dismiss()
    }
}

#Preview {
    let store = AppStore()
    return AddExpenseSheet(tripId: store.trips[0].id)
        .environment(store)
}
