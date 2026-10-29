//
//  PlantDetailViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import SwiftUI
import Observation
import SceneKit

@Observable
@MainActor
class PlantDetailViewModel {
    var uiImage: UIImage? = nil
    var isLoadingImage = false
    
    var scene: SCNScene? = nil
    var isLoadingModel = false
    
    var showDeletePlantConfirmation = false
    
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    private let storageService = StorageService()
    
    func loadImage(for plant: Plant) async {
        // Prevent duplicate network calls if it's already loaded or loading.
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
    
    
    func deletePlant(plant: Plant, plantStore: PlantStore) {
        isLoading = true
        Task {
            defer { isLoading = false }
            errors = []
            
            do {
                try await plantStore.deletePlant(plantId: plant.id)
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
