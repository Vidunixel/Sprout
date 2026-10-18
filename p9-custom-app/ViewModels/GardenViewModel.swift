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
    var showDetailedPlantPanelView = false
    
    var selectedGarden: Garden? = nil
    
    private var storageService = StorageService()
    
    var plantScenes: [Int: SCNScene] = [:]
    var plantLoadingStates: [Int: Bool] = [:]
    
    func setInitialGarden(gardenStore: GardenStore) {
        if selectedGarden == nil {
            if let garden = gardenStore.gardens.first {
                selectedGarden = garden
            }
        }
    }
    
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
}
