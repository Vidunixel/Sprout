//
//  RealtimeService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 21/10/2026.
//

import Foundation
import Supabase

@MainActor
final class RealtimeService {
    private var channel: RealtimeChannelV2?
    private weak var gardenStore: GardenStore?
    private weak var plantStore: PlantStore?
    private weak var taskLogStore: TaskLogStore?
    private weak var taskStore: TaskStore?
    private weak var weatherAdjustmentStore: WeatherAdjustmentStore?
    private weak var weatherAdjustmentTimelineStore: WeatherAdjustmentTimelineStore?
    private let userId: UUID
    
    init(
        userId: UUID,
        gardenStore: GardenStore,
        plantStore: PlantStore,
        taskLogStore: TaskLogStore,
        taskStore: TaskStore,
        weatherAdjustmentStore: WeatherAdjustmentStore,
        weatherAdjustmentTimelineStore: WeatherAdjustmentTimelineStore
    ){
        self.userId = userId
        self.gardenStore = gardenStore
        self.plantStore = plantStore
        self.taskLogStore = taskLogStore
        self.taskStore = taskStore
        self.weatherAdjustmentStore = weatherAdjustmentStore
        self.weatherAdjustmentTimelineStore = weatherAdjustmentTimelineStore
    }
    
    func startListening() async {
        // Setup realtime channel using the V2 API.
        channel = supabase.realtimeV2.channel("public:db_changes")
        
        guard let channel = channel else { return }
        
        // Create stream for all tables.
        let changes = channel.postgresChange(AnyAction.self, schema: "public")
        
        // Run concurrent listening tasks.
        Task { await handleChanges(changes) }
        
        do {
            try await channel.subscribeWithError()
        } catch {
            print(error)
        }
    }
    
    func stopListening() async {
        // Stop the realtime connection.
        await channel?.unsubscribe()
    }
    
    private func handleChanges(_ stream: AsyncStream<AnyAction>) async {
        for await _ in stream {
            // Fetch all data for the user on any change.
            await gardenStore?.fetchGardens(for: userId)
            await plantStore?.fetchPlants(for: userId)
            await taskLogStore?.fetchLogs(for: userId)
            await taskStore?.fetchTasks(for: userId)
            await weatherAdjustmentStore?.fetchAdjustments(for: userId)
            await weatherAdjustmentTimelineStore?.fetchTimelines(for: userId)
        }
    }
}
