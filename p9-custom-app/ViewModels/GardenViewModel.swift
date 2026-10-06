//
//  AddGardenViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import SwiftUI
import Observation
internal import MapKit

@Observable
@MainActor
class GardenViewModel {
    var showAddPlantView = false
    var showAddGardenView = false
    
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var selectedGarden: Garden? = nil
    
    func setInitialGarden(gardenStore: GardenStore) {
        if selectedGarden == nil {
            if let garden = gardenStore.gardens.first {
                selectedGarden = garden
            }
        }
    }
    
    func signOut(authService: AuthService) {
        Task {
            if (errors.isEmpty) {
                do {
                    try await authService.signOut()
                } catch let error as AppError {
                    errors.append(error)
                    feedbackTrigger.toggle()
                }
            }
        }
    }
}
