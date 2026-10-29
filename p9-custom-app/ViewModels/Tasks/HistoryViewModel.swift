//
//  HistoryViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 29/10/2026.
//

import SwiftUI
import Observation

@Observable @MainActor
class HistoryViewModel {
    /// Sort task logs by most recent.
    func sortedLogs(logs: [TaskLog]) -> [TaskLog] {
        return logs.sorted { $0.createdAt > $1.createdAt }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
