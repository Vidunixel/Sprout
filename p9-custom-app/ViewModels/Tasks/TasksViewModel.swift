//
//  TasksViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 27/10/2026.
//

import SwiftUI
import Observation

@Observable @MainActor
class TasksViewModel {
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var showCompleteConfirmation = false
    var taskToComplete: TaskModel? = nil
    
    func latitude(for task: TaskModel, plants: [Plant], gardens: [Garden]) -> Double? {
        guard let plant = plants.first(where: { $0.id == task.plantId }),
              let garden = gardens.first(where: { $0.id == plant.gardenId }) else { return nil }
        return garden.geoLocation.first
    }
    
    func urgentTasks(tasks: [TaskModel], plants: [Plant], gardens: [Garden]) -> [TaskModel] {
        tasks.filter { task in
            let lat = latitude(for: task, plants: plants, gardens: gardens)
            let days = task.daysUntilDue(latitude: lat) ?? 1
            return days <= 0
        }.sorted { t1, t2 in
            let lat1 = latitude(for: t1, plants: plants, gardens: gardens)
            let lat2 = latitude(for: t2, plants: plants, gardens: gardens)
            let date1 = t1.dueDate(latitude: lat1) ?? .distantFuture
            let date2 = t2.dueDate(latitude: lat2) ?? .distantFuture
            return date1 < date2 // Ascending order.
        }
    }
    
    func upcomingTasks(tasks: [TaskModel], plants: [Plant], gardens: [Garden]) -> [TaskModel] {
        tasks.filter { task in
            let lat = latitude(for: task, plants: plants, gardens: gardens)
            let days = task.daysUntilDue(latitude: lat) ?? 1
            return days > 0
        }.sorted { t1, t2 in
            let lat1 = latitude(for: t1, plants: plants, gardens: gardens)
            let lat2 = latitude(for: t2, plants: plants, gardens: gardens)
            let date1 = t1.dueDate(latitude: lat1) ?? .distantFuture
            let date2 = t2.dueDate(latitude: lat2) ?? .distantFuture
            return date1 < date2 // Ascending order.
        }
    }
    
    func logTask(task: TaskModel, taskLogStore: TaskLogStore, taskStore: TaskStore) {
        isLoading = true
        Task {
            defer { isLoading = false }
            errors = []
            
            do {
                // Log the completed cycle.
                _ = try await taskLogStore.createLog(
                    taskId: task.id,
                    cycle: task.currentCycle
                )
                
                // Increment the current cycle on the task.
                try await taskStore.incrementTaskCycle(
                    taskId: task.id,
                    currentCycle: task.currentCycle
                )
            } catch let error as AppError {
                errors.append(error)
            } catch {
                errors.append(AppError(error.localizedDescription, showAlert: true))
            }
            
            if !errors.isEmpty {
                feedbackTrigger.toggle()
            }
        }
    }
}
