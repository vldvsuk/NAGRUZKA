//
//  AddExpenseSheet.swift
//  NAGRUZKA
//

import SwiftUI

struct AddExpenseSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let tripId: UUID

    @State private var expenseDescription = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var paidBy: UUID?
    @State private var splitBetween: Set<UUID> = []

    private var trip: Trip? { store.trip(id: tripId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    amountField
                    descriptionField
                    categoryPicker
                    paidByPicker
                    splitPicker
                    if let amount = Double(amountText), !splitBetween.isEmpty {
                        Text("€\(Formatting.money(amount / Double(splitBetween.count))) per person")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(AppTheme.foreground.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
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
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DESCRIPTION").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            TextField("What was it for?", text: $expenseDescription)
                .font(.system(size: 13))
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.border, lineWidth: 1))
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(ExpenseCategory.allCases) { cat in
                    Button {
                        category = cat
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon).font(.system(size: 11))
                            Text(cat.rawValue).font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(category == cat ? AppTheme.foreground : AppTheme.card)
                        .foregroundStyle(category == cat ? Color.white : AppTheme.foreground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(category == cat ? Color.clear : AppTheme.border, lineWidth: 1))
                    }
                }
            }
        }
    }

    private var paidByPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAID BY").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            HStack(spacing: 8) {
                ForEach(trip?.participants ?? []) { p in
                    Button {
                        paidBy = p.id
                    } label: {
                        VStack(spacing: 6) {
                            AvatarView(participant: p, size: 24)
                            Text(p.name).font(.system(size: 11, weight: .semibold)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(paidBy == p.id ? AppTheme.foreground : AppTheme.card)
                        .foregroundStyle(paidBy == p.id ? Color.white : AppTheme.foreground.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(paidBy == p.id ? Color.clear : AppTheme.border, lineWidth: 1))
                    }
                }
            }
        }
    }

    private var splitPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SPLIT BETWEEN").font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(AppTheme.foreground.opacity(0.35))
            HStack(spacing: 8) {
                ForEach(trip?.participants ?? []) { p in
                    let selected = splitBetween.contains(p.id)
                    Button {
                        if selected { splitBetween.remove(p.id) } else { splitBetween.insert(p.id) }
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
        }
    }

    private var canSubmit: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        return paidBy != nil && !splitBetween.isEmpty && !expenseDescription.trimmingCharacters(in: .whitespaces).isEmpty
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
        store.addExpense(
            to: tripId,
            description: expenseDescription.trimmingCharacters(in: .whitespaces),
            category: category,
            amount: amount,
            paidBy: paidBy,
            splitBetween: Array(splitBetween)
        )
        dismiss()
    }
}

#Preview {
    let store = AppStore()
    return AddExpenseSheet(tripId: store.trips[0].id)
        .environment(store)
}
