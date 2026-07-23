//
//  Formatting.swift
//  NAGRUZKA
//

import Foundation

enum Formatting {
    static func money(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
