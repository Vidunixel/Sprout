//
//  AddGardenViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import SwiftUI
import Observation
internal import MapKit
import Supabase
import SceneKit

@Observable
@MainActor
class GardenViewModel {
    var showAddPlantView = false
    var showAddGardenView = false
    
    var showDeletePlantConfirmation = false
    var plantToDelete: Plant? = nil
    
    var selectedGardenId: Int? = nil
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    private var storageService = StorageService()
    
    var plantScenes: [Int: SCNScene] = [:]
    var plantLoadingStates: [Int: Bool] = [:]
    
    func loadPlantModel(for plant: Plant, userId: UUID) async {
        // Prevent re-downloading if already loaded or is currently loading.
        guard plantScenes[plant.id] == nil, plantLoadingStates[plant.id] != true else { return }
        
        plantLoadingStates[plant.id] = true
        
        do {
            // Donwload model.
            let data = try await storageService.downloadPlantModel(userId: userId, plantId: plant.id)
            
            // Write to temp file.
            let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(plant.id).usdz")
            try data.write(to: tempUrl)
            
            // Render & save state.
            let loadedScene = try SCNScene(url: tempUrl)
            loadedScene.background.contents = UIColor.clear
            self.plantScenes[plant.id] = loadedScene
            self.plantLoadingStates[plant.id] = false
        } catch {
            print("Failed to load 3D model for \(plant.name): \(error.localizedDescription)")
            self.plantLoadingStates[plant.id] = false
        }
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
