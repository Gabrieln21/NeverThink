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
    }

    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }

    func updateTask(_ task: RecurringTask, at index: Int) {
        tasks[index] = task
    }

    func deleteRecurringTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
    }
}
extension RecurringTaskManager {
    func generateFutureTasks(for recurringTask: RecurringTask, into groupManager: TaskGroupManager) {
        let calendar = Calendar.current
        let today = Date()
        
        var currentDate = today
        let iterations = 60 // Generate 2 months of future tasks !!EDIT THIS!!
        
        for _ in 0..<iterations {
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
                    if recurringTask.isTimeSensitive && recurringTask.timeSensitivityType != .busyFromTo {
                        // Use same exact time
                        return calendar.date(
                            bySettingHour: calendar.component(.hour, from: recurringTask.exactTime ?? Date()),
                            minute: calendar.component(.minute, from: recurringTask.exactTime ?? Date()),
                            second: 0,
                            of: currentDate
                        )
                    } else {
                        return nil
                    }
                }(),
                timeRangeStart: {
                    if recurringTask.isTimeSensitive && recurringTask.timeSensitivityType == .busyFromTo {
                        return calendar.date(
                            bySettingHour: calendar.component(.hour, from: recurringTask.timeRangeStart ?? Date()),
                            minute: calendar.component(.minute, from: recurringTask.timeRangeStart ?? Date()),
                            second: 0,
                            of: currentDate
                        )
                    } else {
                        return nil
                    }
                }(),
                timeRangeEnd: {
                    if recurringTask.isTimeSensitive && recurringTask.timeSensitivityType == .busyFromTo {
                        return calendar.date(
                            bySettingHour: calendar.component(.hour, from: recurringTask.timeRangeEnd ?? Date()),
                            minute: calendar.component(.minute, from: recurringTask.timeRangeEnd ?? Date()),
                            second: 0,
                            of: currentDate
                        )
                    } else {
                        return nil
                    }
                }(),
                date: currentDate
            )
            
            groupManager.addTask(newTask)
            
            // Move to next day/week/month
            switch recurringTask.recurringInterval {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            case .weekly:
                currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
            case .yearly:
                currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate)!
            }
        }
    }

}
