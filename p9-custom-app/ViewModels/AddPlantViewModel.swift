//
//  AddPlantViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 1/10/2026.
//

import SwiftUI
import Observation
import Supabase

@Observable
@MainActor
class AddPlantViewModel {
    var dismissView = false
    
    var currentStage: FormStage = .photo
    var isLoading = false
    var identifiedPlants: [PlantNetResult] = []
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var photoImage: UIImage?
    var selectedSpecies: PlantNetResult?
    var species: String = ""
    var name: String = ""
    var isIndoors: Bool = true
    var lightExposure: PlantLightExposure = .medium
    var potSize: PlantPotSize? = .medium
    var garden: Garden?
    
    private var plantNetService = PlantNetService()
    private var openAiService = OpenAiService()
    
    private func uploadPlantPhoto() async throws {
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
    
    func nextStage(
        submit: Bool = false,
        authService: AuthService? = nil,
        plantStore: PlantStore? = nil,
        taskStore: TaskStore? = nil,
        weatherAdjustmentStore: WeatherAdjustmentStore? = nil
    ) {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    if submit, let authService, let plantStore, let taskStore, let weatherAdjustmentStore {
                        try await analyseAndCreatePlant(
                            authService: authService,
                            plantStore: plantStore,
                            taskStore: taskStore,
                            weatherAdjustmentStore: weatherAdjustmentStore
                        )
                        
                    } else if let next = FormStage(rawValue: currentStage.rawValue + 1) {
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
    
    func previousStage() {
        if let prev = FormStage(rawValue: currentStage.rawValue - 1) {
            currentStage = prev
        }
    }
    
    private func analyseAndCreatePlant(
        authService: AuthService,
        plantStore: PlantStore,
        taskStore: TaskStore,
        weatherAdjustmentStore: WeatherAdjustmentStore
    ) async throws {
        let species = selectedSpecies?.species.scientificNameWithoutAuthor ?? self.species
        
        if let garden = garden, let userId = authService.session?.user.id {
            // Get openAi result.
            let openAiResult = try await openAiService.analysePlant(
                species: species,
                lightExposure: lightExposure,
                isIndoors: isIndoors,
                potSize: potSize,
                city: garden.city,
                geoLocation: garden.geoLocation
            )
            
            // Save plant.
            let plant = try await plantStore.createPlant(
                userId: userId,
                species: species,
                name: name,
                lightExposure: lightExposure,
                potSize: potSize,
                gardenId: garden.id
            )
            
            // Save tasks and weather adjustments.
            for openAiTask in openAiResult.tasks {
                let task = try await taskStore.createTask(
                    plantId: plant.id,
                    name: openAiTask.taskName,
                    instructions: openAiTask.instructions,
                    springIntervalDays: openAiTask.schedule.springIntervalDays,
                    summerIntervalDays: openAiTask.schedule.summerIntervalDays,
                    autumnIntervalDays: openAiTask.schedule.autumnIntervalDays,
                    winterIntervalDays: openAiTask.schedule.winterIntervalDays
                )
                
                let weatherAdjustmentsMirror = Mirror(reflecting: openAiTask.weatherAdjustments)
                
                for weatherAdjustment in weatherAdjustmentsMirror.children {
                    if let key = weatherAdjustment.label, let value = weatherAdjustment.value as? Double {
                        try await weatherAdjustmentStore.createAdjustment(
                            taskId: task.id,
                            name: key,
                            multiplier: value
                        )
                    }
                }
            }
            
            // Dismiss view
            dismissView = true
        } else {
            throw AppError("Invalid fields.", showAlert: true)
        }
    }
    
    private func validateErrors() {
        errors = []
        
        switch currentStage {
        case .species:
            validateSpecies()
        case .name:
            validateName()
        case .garden:
            validateGarden()
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
    
    private func validateGarden() {
        if garden == nil {
            errors.append(AppError("Please select a garden to continue.", showAlert: true))
        }
    }
    
    func selectPlantSpecies(plant: PlantNetResult) {
        selectedSpecies = plant
        species = ""
    }
}
