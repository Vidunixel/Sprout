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
    
    func fetchTasks(for plantId: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.tasks = try await supabase
                .from("tasks")
                .select()
                .eq("plant_id", value: plantId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createTask(
        plantId: Int,
        name: String,
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
            .select()
            .single()
            .execute()
            .value
        
        await fetchTasks(for: plantId)
        
        return response
    }
}
