//
//  TaskDetailViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 26/10/2026.
//

import SwiftUI
import Observation

@Observable @MainActor class TaskDetailViewModel {
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    var showCompleteConfirmation = false
    
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
