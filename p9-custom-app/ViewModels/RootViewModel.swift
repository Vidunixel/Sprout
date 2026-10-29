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
        
        // Handle initial notification permissions if no userdefault is set.
        if UserDefaults.standard.object(forKey: "isTaskRemindersEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "isTaskRemindersEnabled")
            NotificationService.shared.requestPermission { granted in
                if !granted {
                    UserDefaults.standard.set(false, forKey: "isTaskRemindersEnabled")
                }
            }
        }
        
        // Evaluate weather adjustments and sync notifications.
        await evaluateWeatherAndSyncNotifications(userId: userId, gardenStore: gardenStore, plantStore: plantStore, taskStore: taskStore)
        
        // Listen to db changes.
        realtimeService = RealtimeService(
            userId: userId,
            gardenStore: gardenStore,
            plantStore: plantStore,
            taskLogStore: taskLogStore,
            taskStore: taskStore,
            weatherAdjustmentStore: weatherAdjustmentStore,
            weatherAdjustmentTimelineStore: weatherAdjustmentTimelineStore
        )
        await realtimeService?.startListening()
    }
    
    func evaluateWeatherAndSyncNotifications(
        userId: UUID,
        gardenStore: GardenStore,
        plantStore: PlantStore,
        taskStore: TaskStore
    ) async {
        // Evaluate weather adjustments.
        _ = await weatherEvaluationService.evaluateAndSync(gardens: gardenStore.gardens)
        
        // Sync notifications if enabled.
        if UserDefaults.standard.bool(forKey: "isTaskRemindersEnabled") {
            await taskStore.fetchTasks(for: userId) // Fetch fresh tasks (realtime may be delayed).
            NotificationService.shared.syncNotifications(
                tasks: taskStore.tasks,
                plants: plantStore.plants,
                gardens: gardenStore.gardens
            )
        }
    }
    
    
    // Stop listening to db changes when the user logs out.
    func cleanup() async {
        await realtimeService?.stopListening()
        realtimeService = nil
    }
}
