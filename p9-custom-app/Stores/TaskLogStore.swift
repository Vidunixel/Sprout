//
//  TaskLogStore.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation
import Supabase
internal import Combine

@MainActor
final class TaskLogStore: ObservableObject {
    @Published private(set) var logs: [TaskLog] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    func fetchLogs(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.logs = try await supabase
                .from("tasks_log")
                .select("*, tasks!inner(plants!inner(user_id))")
                .eq("tasks.plants.user_id", value: userId)
                .execute()
                .value
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func createLog(taskId: Int, cycle: Int) async throws -> TaskLog {
        let newLog = TaskLogInsert(
            taskId: taskId,
            cycle: cycle
        )
        
        let response: TaskLog = try await supabase
            .from("tasks_log")
            .insert(newLog)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
}
