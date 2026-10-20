//
//  PlantDetailViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import SwiftUI
import Observation

@Observable
@MainActor
class PlantDetailViewModel {
    var plant: Plant
    var uiImage: UIImage? = nil
    var isLoadingImage = false
    
    private let storageService = StorageService()
    
    init(plant: Plant) {
        self.plant = plant
    }
    
    func loadImage() async {
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
}
