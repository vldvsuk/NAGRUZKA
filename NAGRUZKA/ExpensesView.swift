//
//  ExpensesView.swift
//  NAGRUZKA
//

import SwiftUI

struct ExpensesView: View {
    @Environment(TripStore.self) private var store
    @State private var showingAddExpense = false

    private var sortedExpenses: [Expense] {
        store.expenses.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedExpenses) { expense in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(expense.description, systemImage: expense.category.icon)
                            Spacer()
                            Text(expense.amount, format: .currency(code: "EUR"))
                        }
                        let payerNames = expense.paidBy
                            .map { store.name(for: $0.participantId) }
                            .joined(separator: ", ")
                        Text("Paid by \(payerNames)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        store.removeExpense(sortedExpenses[index])
                    }
                }
            }
            .overlay {
                if store.expenses.isEmpty {
                    ContentUnavailableView(
                        "No expenses yet",
                        systemImage: "receipt",
                        description: Text("Tap + to add your first expense")
                    )
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(store.participants.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView()
            }
        }
    }
}

#Preview {
    ExpensesView()
        .environment(TripStore())
}
