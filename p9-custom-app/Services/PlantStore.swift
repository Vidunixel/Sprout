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
                .select()
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
    ) async throws {
        let newPlant = PlantInsert(
            userId: userId,
            species: species,
            name: name,
            lightExposure: lightExposure,
            isIndoors: isIndoors,
            potSize: potSize,
            gardenId: gardenId
        )
        
        try await supabase
            .from("plants")
            .insert(newPlant)
            .execute()
        
        await fetchPlants(for: userId)
    }
}
