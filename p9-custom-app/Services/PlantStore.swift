//
//  PlantStore.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation
import Supabase
internal import Combine

@MainActor
final class PlantStore: ObservableObject {
    @Published private(set) var plants: [Plant] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    func fetchPlants(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.plants = try await supabase
                .from("plants")
                .select("*, tasks(*, weather_adjustments(*))")
                .eq("user_id", value: userId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createPlant(
        userId: UUID,
        species: String,
        name: String,
        lightExposure: PlantLightExposure,
        isIndoors: Bool = true,
        potSize: PlantPotSize? = nil,
        gardenId: Int
    ) async throws -> Plant {
        let newPlant = PlantInsert(
            userId: userId,
            species: species,
            name: name,
            lightExposure: lightExposure,
            isIndoors: isIndoors,
            potSize: potSize,
            gardenId: gardenId
        )
        
        let response: Plant = try await supabase
            .from("plants")
            .insert(newPlant)
            .select("*, tasks(*, weather_adjustments(*))")
            .single()
            .execute()
            .value
        
        await fetchPlants(for: userId)
        return response
    }
    
    func deletePlant(
        userId: UUID,
        plantId: Int
    ) async throws {
        try await supabase
          .from("plants")
          .delete()
          .eq("id", value: plantId)
          .execute()
    }
}
