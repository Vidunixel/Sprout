//
//  WeatherAdjustmentStore.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation
import Supabase
internal import Combine

@MainActor
final class WeatherAdjustmentStore: ObservableObject {
    @Published private(set) var adjustments: [WeatherAdjustment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    func fetchAdjustments(for taskId: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.adjustments = try await supabase
                .from("weather_adjustments")
                .select()
                .eq("task_id", value: taskId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createAdjustment(
        taskId: Int,
        name: String,
        multiplier: Float
    ) async throws {
        let newAdjustment = WeatherAdjustmentInsert(
            taskId: taskId,
            name: name,
            multiplier: multiplier
        )
        
        try await supabase
            .from("weather_adjustments")
            .insert(newAdjustment)
            .execute()
        
        await fetchAdjustments(for: taskId)
    }
}
