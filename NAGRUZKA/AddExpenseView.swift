//
//  AddExpenseView.swift
//  NAGRUZKA
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(TripStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var expenseDescription = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var paidById: UUID?
    @State private var splitAmongIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Description", text: $expenseDescription)
                    TextField("Amount", text: $amountText)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section("Paid by") {
                    Picker("Paid by", selection: $paidById) {
                        Text("Select").tag(UUID?.none)
                        ForEach(store.participants) { participant in
                            Text(participant.name).tag(UUID?.some(participant.id))
                        }
                    }
                }

                Section("Split equally between") {
                    ForEach(store.participants) { participant in
                        Toggle(participant.name, isOn: Binding(
                            get: { splitAmongIds.contains(participant.id) },
                            set: { isOn in
                                if isOn { splitAmongIds.insert(participant.id) }
                                else { splitAmongIds.remove(participant.id) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if splitAmongIds.isEmpty {
                    splitAmongIds = Set(store.participants.map(\.id))
                }
            }
        }
    }

    private var canSave: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        return paidById != nil
            && !splitAmongIds.isEmpty
            && !expenseDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        guard let amount = Double(amountText),
              let paidById,
              let payer = store.participants.first(where: { $0.id == paidById }) else { return }

        let splitAmong = store.participants.filter { splitAmongIds.contains($0.id) }
        store.addEqualSplitExpense(
            description: expenseDescription,
            amount: amount,
            category: category,
            paidBy: payer,
            splitAmong: splitAmong
        )
        dismiss()
    }
}

#Preview {
    let store = TripStore()
    store.addParticipant(name: "Vlad")
    store.addParticipant(name: "Dima")
    return AddExpenseView()
        .environment(store)
}
