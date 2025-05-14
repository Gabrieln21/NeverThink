//
//  DateFormatter.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/29/25.
//
import Foundation

extension DateFormatter {
    // Attempts to parse a time string using several common formats.
    
    // - Parameter timeString: The string representing a time ("3:30 PM", "15:45")
    // - Returns: A `Date` object if parsing succeeds, otherwise nil
    static func parseTimeString(_ timeString: String) -> Date? {
        let formats = ["h:mm a", "hh:mm a", "H:mm", "HH:mm"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            // Try parsing the time string with the current format
            if let date = formatter.date(from: timeString) {
                return date
            }
        }
        // If none of the formats matched, return nil
        return nil
    }
}

