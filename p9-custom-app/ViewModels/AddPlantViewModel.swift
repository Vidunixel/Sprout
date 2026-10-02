//
//  AddPlantViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 1/10/2026.
//

import SwiftUI
import Observation

@Observable
@MainActor
class AddPlantViewModel {
    var currentStage: FormStage = .photo
    var isLoading = false
    var identifiedPlants: [PlantNetResult] = []
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    enum PlantLightExposure: String, CaseIterable, Identifiable {
        case Low = "LOW"
        case Medium = "MEDIUM"
        case High = "HIGH"
        
        var id: Self { self }
    }
    
    var photoImage: UIImage?
    var selectedSpecies: PlantNetResult?
    var species: String = ""
    var name: String = ""
    var isIndoors: Bool = true
    var lightExposure: PlantLightExposure = .Medium
    
    private var plantNetService = PlantNetService()
    
    func uploadPlantPhoto() async throws {
        // Compress image.
        guard let image = photoImage, let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw AppError("Could not process the image.", showAlert: true)
        }
        
        do {
            let response = try await plantNetService.identifyPlant(imageData: imageData)
            identifiedPlants = response.results
            
            if !identifiedPlants.isEmpty {
                currentStage = .species
            } else {
                throw AppError("No plant species could be identified.", showAlert: true)
            }
        } catch {
            throw AppError("Failed to identify plant.", showAlert: true)
        }
    }
    
    func nextStage() {
        if let next = FormStage(rawValue: currentStage.rawValue + 1) {
            isLoading = true
            Task {
                defer { isLoading = false }
                validateErrors()
                if (errors.isEmpty) {
                    do {
                        switch currentStage {
                        case .photo:
                            guard photoImage != nil else {
                                throw AppError("Please select or capture a photo to continue.", showAlert: true)
                            }
                            
                            try await uploadPlantPhoto()
                            currentStage = next
                        case .species:
                            if selectedSpecies == nil {
                                name = species
                            } else {
                                name = selectedSpecies?.species.scientificNameWithoutAuthor ?? ""
                            }
                            
                            currentStage = next
                        default:
                            currentStage = next
                        }
                    } catch let error as AppError {
                        errors.append(error)
                    } catch {
                        errors.append(AppError(error.localizedDescription, showAlert: true))
                    }
                }
                
                if !errors.isEmpty {
                    feedbackTrigger.toggle()
                }
            }
        }
    }
    
    func previousStage() {
        if let prev = FormStage(rawValue: currentStage.rawValue - 1) {
            currentStage = prev
        }
    }
    
    private func validateErrors() {
        errors = []
        
        switch currentStage {
        case .species:
            validateSpecies()
        case .name:
            validateName()
        default:
            break
        }
    }
    
    private func validateSpecies() {
        if species.isEmpty && selectedSpecies == nil {
            errors.append(AppError("Please select or manually enter a species.", showAlert: true))
        }
    }
    
    private func validateName() {
        if name.isEmpty {
            errors.append(AppError("Name is required.", "name_empty"))
        }
    }
    
    func selectPlantSpecies(plant: PlantNetResult) {
        selectedSpecies = plant
        species = ""
    }
}
