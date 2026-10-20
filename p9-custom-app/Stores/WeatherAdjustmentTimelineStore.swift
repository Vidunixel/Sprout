//
//  WeatherAdjustmentTimelineStore.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation
import Supabase
internal import Combine

@MainActor
final class WeatherAdjustmentTimelineStore: ObservableObject {
    @Published private(set) var timelines: [WeatherAdjustmentTimeline] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    func fetchTimelines(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.timelines = try await supabase
                .from("weather_adjustments_timeline")
                .select("*, weather_adjustments!inner(tasks!inner(plants!inner(user_id)))")
                .eq("weather_adjustments.tasks.plants.user_id", value: userId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createTimeline(weatherAdjustmentId: Int, cycle: Int) async throws -> WeatherAdjustmentTimeline {
        let newTimeline = WeatherAdjustmentTimelineInsert(
            weatherAdjustmentId: weatherAdjustmentId,
            cycle: cycle
        )
        
        let response: WeatherAdjustmentTimeline = try await supabase
            .from("weather_adjustments_timeline")
            .insert(newTimeline)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
}
