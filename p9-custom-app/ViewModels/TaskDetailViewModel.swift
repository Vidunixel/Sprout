//
//  TaskDetailViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 26/10/2026.
//

import SwiftUI
import Observation
import SceneKit

@Observable @MainActor class TaskDetailViewModel {
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    var showCompleteConfirmation = false
    
    var scene: SCNScene? = nil
    var isLoadingModel = false
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
    
    func loadModel(for plant: Plant) async {
        guard scene == nil, !isLoadingModel else { return }
        
        isLoadingModel = true
        do {
            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(plant.id).usdz")
            
            // Check if the file already exists locally.
            if !FileManager.default.fileExists(atPath: tempUrl.path) {
                let data = try await storageService.downloadPlantModel(userId: plant.userId, plantId: plant.id)
                try data.write(to: tempUrl)
            }
            
            let loadedScene = try SCNScene(url: tempUrl)
            loadedScene.background.contents = UIColor.clear
            self.scene = loadedScene
        } catch {
            print("Failed to load 3D model for \(plant.name): \(error.localizedDescription)")
        }
        isLoadingModel = false
    }
}
