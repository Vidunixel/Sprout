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
    
    var uiImage: UIImage? = nil
    var isLoadingImage = false
    private let storageService = StorageService()
    
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
    
    func loadImage(for plant: Plant) async {
        guard uiImage == nil, !isLoadingImage else { return }
        
        isLoadingImage = true
        do {
            let data = try await storageService.downloadPlantImage(userId: plant.userId, plantId: plant.id)
            if let downloadedImage = UIImage(data: data) {
                self.uiImage = downloadedImage
            }
        } catch {
            print("Failed to load plant image: \(error.localizedDescription)")
        }
        isLoadingImage = false
    }
}
