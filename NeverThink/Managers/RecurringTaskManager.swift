//
//  RecurringTaskManager.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/26/25.
//

import Foundation
import SwiftUI

class RecurringTaskManager: ObservableObject {
    @Published var tasks: [RecurringTask] = []

    func addTask(_ task: RecurringTask) {
        tasks.append(task)
        saveToDisk()
    }

    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    func updateTask(_ task: RecurringTask, at index: Int) {
        tasks[index] = task
        saveToDisk()
    }

    func deleteRecurringTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveToDisk()
    }
}

extension RecurringTaskManager {
    func generateFutureTasks(for recurringTask: RecurringTask, into groupManager: TaskGroupManager) {
        let calendar = Calendar.current
        let today = Date()

        var currentDate = today
        let iterations = 60 // About 2 months !make selectable!!

        for _ in 0..<iterations {
            let weekday = calendar.component(.weekday, from: currentDate) - 1 // Sunday = 0

            if recurringTask.recurringInterval == .weekly {
                if !(recurringTask.selectedWeekdays?.contains(weekday) ?? false) {
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                    continue
                }
            }

            func adjustTime(_ time: Date?) -> Date? {
                guard let time = time else { return nil }
                let components = calendar.dateComponents([.hour, .minute], from: time)
                return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: currentDate)
            }

            let newTask = UserTask(
                id: UUID(),
                title: recurringTask.title,
                duration: recurringTask.duration,
                isTimeSensitive: recurringTask.isTimeSensitive,
                urgency: recurringTask.urgency,
                isLocationSensitive: recurringTask.location != nil && recurringTask.location != "Home",
                location: recurringTask.location,
                category: recurringTask.category,
                timeSensitivityType: recurringTask.timeSensitivityType,
                exactTime: {
                    if recurringTask.isTimeSensitive {
                        switch recurringTask.timeSensitivityType {
                        case .startsAt, .dueBy:
                            return adjustTime(recurringTask.exactTime)
                        default:
                            return nil
                        }
                    }
                    return nil
                }(),
                timeRangeStart: recurringTask.isTimeSensitive && recurringTask.timeSensitivityType == .busyFromTo
                    ? adjustTime(recurringTask.timeRangeStart)
                    : nil,
                timeRangeEnd: recurringTask.isTimeSensitive && recurringTask.timeSensitivityType == .busyFromTo
                    ? adjustTime(recurringTask.timeRangeEnd)
                    : nil,
                date: currentDate
            )

            groupManager.addTask(newTask)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
extension RecurringTaskManager {
    private var fileURL: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return path.appendingPathComponent("recurring_tasks.json")
    }

    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: fileURL)
            print("✅ Recurring tasks saved to disk")
        } catch {
            print("❌ Failed to save recurring tasks: \(error)")
        }
    }

    func loadFromDisk() {
        do {
            let data = try Data(contentsOf: fileURL)
            let loaded = try JSONDecoder().decode([RecurringTask].self, from: data)
            self.tasks = loaded
            print("✅ Recurring tasks loaded from disk")
        } catch {
            print("⚠️ No saved recurring tasks or failed to load: \(error)")
        }
    }
}

