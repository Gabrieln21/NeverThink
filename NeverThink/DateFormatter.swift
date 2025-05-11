//
//  DateFormatter.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/29/25.
//
import Foundation

extension DateFormatter {
    static func parseTimeString(_ timeString: String) -> Date? {
        let formats = ["h:mm a", "hh:mm a", "H:mm", "HH:mm"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        return nil
    }
}

