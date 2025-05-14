//
//  TodayPlanManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//
import Foundation
import SwiftUI

// Manages all AI-generated daily plans, organized by date.
// Handles in-memory storage, task operations, and UserDefaults persistence.
class TodayPlanManager: ObservableObject {
    // A dictionary mapping dates to arrays of planned tasks
    @Published var todayPlansByDate: [Date: [PlannedTask]] = [:] {
        didSet {
            saveToDisk()
        }
    }

    init() {
        loadFromDisk()
    }
    
    // Saves a full set of planned tasks for a given day
    func saveTodayPlan(for date: Date, _ tasks: [PlannedTask]) {
        Task { @MainActor in
            replaceAllTasks(for: date, with: tasks)
        }
    }
    
    // Returns the full plan for a specific date (or an empty array if none)
    func getTodayPlan(for date: Date) -> [PlannedTask] {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return todayPlansByDate[normalizedDate] ?? []
    }
    
    // Returns true if a plan exists for a given date
    func hasPlan(for date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return !(todayPlansByDate[normalizedDate]?.isEmpty ?? true)
    }

    // Removes the plan for a given date
    func clearTodayPlan(for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        todayPlansByDate.removeValue(forKey: normalizedDate)
    }

    // Replaces an existing task with a new version (same ID)
    func updateTask(_ task: PlannedTask) {
        let normalizedDate = Calendar.current.startOfDay(for: task.date)

        if var tasksForDate = todayPlansByDate[normalizedDate],
           let index = tasksForDate.firstIndex(where: { $0.id == task.id }) {
            tasksForDate[index] = task
            todayPlansByDate[normalizedDate] = tasksForDate
        }
    }
    
    // Removes a task with a given UUID from any day's plan
    func removeTaskById(_ id: UUID) {
        for (date, tasks) in todayPlansByDate {
            if let index = tasks.firstIndex(where: { $0.id == id.uuidString }) {
                var updatedTasks = tasks
                updatedTasks.remove(at: index)
                todayPlansByDate[date] = updatedTasks
            }
        }
    }

    // Inserts or updates a task for the day it belongs to
    func replaceOrInsertTask(_ task: PlannedTask) {
        let normalizedDate = Calendar.current.startOfDay(for: task.date)
        if var tasksForDate = todayPlansByDate[normalizedDate] {
            if let index = tasksForDate.firstIndex(where: { $0.id == task.id }) {
                tasksForDate[index] = task
            } else {
                tasksForDate.append(task)
            }
            todayPlansByDate[normalizedDate] = tasksForDate
        } else {
            todayPlansByDate[normalizedDate] = [task]
        }
    }

    // Marks a task as completed and persists the change
    func markTaskCompleted(_ task: PlannedTask) {
        let day = Calendar.current.startOfDay(for: task.date)
        if var tasks = todayPlansByDate[day],
           let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            todayPlansByDate[day] = tasks
            saveToDisk()
        }
    }

    // Replaces the entire task list for a given day, with animation
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
