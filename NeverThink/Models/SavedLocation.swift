//
//  SavedLocation.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 5/3/25.
//
import Foundation

struct SavedLocation: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var address: String
}
