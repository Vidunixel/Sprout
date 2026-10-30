//
//  TaskStore.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation
import Supabase
internal import Combine

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    func fetchTasks(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.tasks = try await supabase
                .from("tasks")
                .select("*, tasks_log(*), weather_adjustments(*, weather_adjustments_timeline(*)), plants!inner(user_id)")
                .eq("plants.user_id", value: userId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createTask(
        plantId: Int,
        name: String,
        sfSymbol: String? = nil,
        sfSymbolColour: String? = nil,
        instructions: String,
        springIntervalDays: Int? = nil,
        summerIntervalDays: Int? = nil,
        autumnIntervalDays: Int? = nil,
        winterIntervalDays: Int? = nil,
        currentCycle: Int = 1
    ) async throws -> TaskModel {
        let newTask = TaskInsert(
            plantId: plantId,
            name: name,
            sfSymbol: sfSymbol,
            sfSymbolColour: sfSymbolColour,
            instructions: instructions,
            springIntervalDays: springIntervalDays,
            summerIntervalDays: summerIntervalDays,
            autumnIntervalDays: autumnIntervalDays,
            winterIntervalDays: winterIntervalDays,
            currentCycle: currentCycle
        )
        
        let response: TaskModel = try await supabase
            .from("tasks")
            .insert(newTask)
            .select("*, tasks_log(*), weather_adjustments(*, weather_adjustments_timeline(*))")
            .single()
            .execute()
            .value
        
        return response
    }
}
