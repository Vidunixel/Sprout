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
    var hasNetworkError = false
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
    
    func syncAllData(
        userId: UUID,
        gardenStore: GardenStore,
        plantStore: PlantStore,
        taskLogStore: TaskLogStore,
        taskStore: TaskStore,
        weatherAdjustmentStore: WeatherAdjustmentStore,
        weatherAdjustmentTimelineStore: WeatherAdjustmentTimelineStore
    ) async throws {
        // Fetch all data concurrently.
        async let fetchGardens: () = gardenStore.fetchGardens(for: userId)
        async let fetchPlants: () = plantStore.fetchPlants(for: userId)
        async let fetchLogs: () = taskLogStore.fetchLogs(for: userId)
        async let fetchTasks: () = taskStore.fetchTasks(for: userId)
        async let fetchAdjustments: () = weatherAdjustmentStore.fetchAdjustments(for: userId)
        async let fetchTimelines: () = weatherAdjustmentTimelineStore.fetchTimelines(for: userId)
        _ = try await (fetchGardens, fetchPlants, fetchLogs, fetchTasks, fetchAdjustments, fetchTimelines)
        
        // Evaluate weather and sync notifications based on fresh data.
        _ = await weatherEvaluationService.evaluateAndSync(gardens: gardenStore.gardens)
        
        NotificationService.shared.syncNotifications(
            tasks: taskStore.tasks,
            plants: plantStore.plants,
            gardens: gardenStore.gardens
        )
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
        hasNetworkError = false
        defer { isBooting = false }
        
        // Setup initial notification permissions if missing.
        if UserDefaults.standard.object(forKey: "isTaskRemindersEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "isTaskRemindersEnabled")
            NotificationService.shared.requestPermission { granted in
                if !granted {
                    UserDefaults.standard.set(false, forKey: "isTaskRemindersEnabled")
                }
            }
        }
        
        do {
            // Initial fetch and sync.
            try await syncAllData(
                userId: userId, gardenStore: gardenStore, plantStore: plantStore,
                taskLogStore: taskLogStore, taskStore: taskStore,
                weatherAdjustmentStore: weatherAdjustmentStore, weatherAdjustmentTimelineStore: weatherAdjustmentTimelineStore
            )
            
            // Setup Realtime.
            realtimeService = RealtimeService(
                userId: userId, gardenStore: gardenStore, plantStore: plantStore,
                taskLogStore: taskLogStore, taskStore: taskStore,
                weatherAdjustmentStore: weatherAdjustmentStore, weatherAdjustmentTimelineStore: weatherAdjustmentTimelineStore
            )
            
            Task {
                await realtimeService?.startListening()
            }
        } catch {
            print("Boot failed: \(error.localizedDescription)")
            hasNetworkError = true
        }
    }
    
    
    // Stop listening to db changes when the user logs out.
    func cleanup() async {
        await realtimeService?.stopListening()
        realtimeService = nil
    }
}
