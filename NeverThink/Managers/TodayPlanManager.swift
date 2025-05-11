import Foundation
import SwiftUI

class TodayPlanManager: ObservableObject {
    @Published var todayPlansByDate: [Date: [PlannedTask]] = [:] {
        didSet {
            saveToDisk()
        }
    }

    init() {
        loadFromDisk()
    }

    func saveTodayPlan(for date: Date, _ tasks: [PlannedTask]) {
        Task { @MainActor in
            replaceAllTasks(for: date, with: tasks)
        }
    }

    func getTodayPlan(for date: Date) -> [PlannedTask] {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return todayPlansByDate[normalizedDate] ?? []
    }

    func clearTodayPlan(for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        todayPlansByDate.removeValue(forKey: normalizedDate)
    }

    func updateTask(_ task: PlannedTask) {
        let normalizedDate = Calendar.current.startOfDay(for: task.date)

        if var tasksForDate = todayPlansByDate[normalizedDate],
           let index = tasksForDate.firstIndex(where: { $0.id == task.id }) {
            tasksForDate[index] = task
            todayPlansByDate[normalizedDate] = tasksForDate
        }
    }

    func markTaskCompleted(_ task: PlannedTask) {
        let day = Calendar.current.startOfDay(for: Date())
        if var tasks = todayPlansByDate[day],
           let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            todayPlansByDate[day] = tasks
        }
    }

    @MainActor
    func replaceAllTasks(for date: Date, with newTasks: [PlannedTask]) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        withAnimation {
            todayPlansByDate[normalizedDate] = newTasks
        }
    }

    // Persistence

    private func saveToDisk() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(todayPlansByDate)
            UserDefaults.standard.set(data, forKey: "savedTodayPlans")
        } catch {
            print("❌ Failed to save todayPlansByDate to disk: \(error)")
        }
    }

    func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: "savedTodayPlans") else {
            print("📭 No saved plans found in UserDefaults.")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let decoded = try decoder.decode([Date: [PlannedTask]].self, from: data)
            todayPlansByDate = decoded
            print("✅ Loaded saved plans from disk.")
        } catch {
            print("❌ Failed to decode saved todayPlansByDate: \(error)")
        }
    }
}
