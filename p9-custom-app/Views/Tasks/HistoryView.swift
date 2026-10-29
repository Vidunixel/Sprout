//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var taskLogStore: TaskLogStore
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var plantStore: PlantStore
    
    @State private var viewModel = HistoryViewModel()
    
    var body: some View {
        let logs = viewModel.sortedLogs(logs: taskLogStore.logs)
        
        Group {
            if logs.isEmpty {
                Text("No completed tasks yet.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("Completed Tasks") {
                        ForEach(logs) { log in
                            if let task = taskStore.tasks.first(where: { $0.id == log.taskId }),
                               let plant = plantStore.plants.first(where: { $0.id == task.plantId }) {
                                HistoryRowView(log: log, task: task, plant: plant, viewModel: viewModel)
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("History")
        .appBackground()
    }
}

struct HistoryRowView: View {
    let log: TaskLog
    let task: TaskModel
    let plant: Plant
    let viewModel: HistoryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(plant.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(viewModel.formatDate(log.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                
                Text("Cycle \(log.cycle)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
            }
            .lineLimit(1)
        }
    }
}
