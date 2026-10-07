//
//  GardenStore.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 3/10/2026.
//

import Foundation
import Supabase
internal import Combine

@MainActor
final class GardenStore: ObservableObject {
    @Published private(set) var gardens: [Garden] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    func fetchGardens(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.gardens = try await supabase
                .from("gardens")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createGarden(name: String, city: String, geoLocation: [Double], userId: UUID) async throws -> Garden {
        let newGarden = GardenInsert(
            name: name,
            city: city,
            geoLocation: geoLocation
        )
        
        let response: Garden = try await supabase
            .from("gardens")
            .insert(newGarden)
            .select()
            .single()
            .execute()
            .value
            
        await fetchGardens(for: userId)
        
        return response
    }
}
