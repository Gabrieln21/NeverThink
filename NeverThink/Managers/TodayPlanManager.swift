//
//  TodayPlanManager.swift
//  NeverThink
//
//  Created by Gabriel Hernandez on 4/25/25.
//
//
//  TodayPlanManager.swift
//  NeverThink
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

