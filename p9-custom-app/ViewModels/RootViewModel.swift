//
//  RootViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import SwiftUI
import Observation
import Supabase

@Observable @MainActor
class RootViewModel {
    var showUpdatePasswordView = false
    var isBooting = true
    private let weatherEvaluationService = WeatherEvaluationService()
    private var realtimeService: RealtimeService?
    
    /// Handles incoming deep links, specifically for Supabase Auth.
    func handleOpenURL(_ url: URL) {
        if url.host == "auth" {
            Task {
                do {
                    // Log user in
                    try await supabase.auth.session(from: url)
                    
                    if url.path == "/reset-password" {
                        showUpdatePasswordView = true
                    }
                } catch {
                    print("Auth error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func performBootTasks(
        userId: UUID,
        gardenStore: GardenStore,
        plantStore: PlantStore,
        taskLogStore: TaskLogStore,
        taskStore: TaskStore,
        weatherAdjustmentStore: WeatherAdjustmentStore,
        weatherAdjustmentTimelineStore: WeatherAdjustmentTimelineStore
    ) async {
        isBooting = true
        defer { isBooting = false }
        
        await gardenStore.fetchGardens(for: userId)
        await plantStore.fetchPlants(for: userId)
        await taskLogStore.fetchLogs(for: userId)
        await taskStore.fetchTasks(for: userId)
        await weatherAdjustmentStore.fetchAdjustments(for: userId)
        await weatherAdjustmentTimelineStore.fetchTimelines(for: userId)
        
        // Evaluate weather adjustments.
        _ = await weatherEvaluationService.evaluateAndSync(gardens: gardenStore.gardens)
        
        // Listen to db changes.
        realtimeService = RealtimeService(
            userId: userId,
            gardenStore: gardenStore,
            plantStore: plantStore
        )
        await realtimeService?.startListening()
    }
    
    
    // Stop listening to db changes when the user logs out.
    func cleanup() async {
        await realtimeService?.stopListening()
        realtimeService = nil
    }
}
