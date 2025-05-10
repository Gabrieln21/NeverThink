//
//  TodayPlanManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/25/25.
//


import Foundation

class TodayPlanManager: ObservableObject {
    @Published var todayPlansByDate: [Date: [PlannedTask]] = [:]

    func saveTodayPlan(for date: Date, _ tasks: [PlannedTask]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        todayPlansByDate[normalizedDate] = tasks
    }

    func getTodayPlan(for date: Date) -> [PlannedTask] {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return todayPlansByDate[normalizedDate] ?? []
    }

    func clearTodayPlan(for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        todayPlansByDate.removeValue(forKey: normalizedDate)
    }
    func markTaskCompleted(_ task: PlannedTask) {
        let day = Calendar.current.startOfDay(for: Date())
        if var tasks = todayPlansByDate[day] {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].isCompleted = true
                todayPlansByDate[day] = tasks
            }
        }
    }



    
}


