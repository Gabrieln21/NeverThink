//
//  TodayPlanManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//

import Foundation

class TodayPlanManager: ObservableObject {
    @Published var todayPlan: [PlannedTask] = []

    func saveTodayPlan(_ tasks: [PlannedTask]) {
        todayPlan = tasks
    }

    func clearTodayPlan() {
        todayPlan.removeAll()
    }
}

