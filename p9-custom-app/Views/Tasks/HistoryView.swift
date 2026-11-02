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
                VStack(spacing: 24) {
                    Image(uiImage: .schedule)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()
                        .accessibilityHidden(true)
                    
                    Text("No completed tasks yet.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section("Completed Tasks") {
                        ForEach(logs) { log in
                            if let task = taskStore.tasks.first(where: { $0.id == log.taskId }),
                               let plant = plantStore.plants.first(where: { $0.id == task.plantId }) {
                                NavigationLink(destination: TaskDetailView(taskId: task.id, plantId: plant.id, showPlantReference: true, taskLogId: log.id)) {
                                    HistoryRowView(log: log, task: task, plant: plant, viewModel: viewModel)
                                }
                                .accessibilityHint("Opens task completion log details")
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    .navigationLinkIndicatorVisibility(.hidden)
                }
                .listRowSeparator(.hidden)
                .listRowSpacing(12)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("History")
        .navigationSubtitle("A record of your past plant care tasks.")
        .appBackground()
    }
}

struct HistoryRowView: View {
    let log: TaskLog
    let task: TaskModel
    let plant: Plant
    let viewModel: HistoryViewModel
    
    private var completionStatus: (text: String, color: Color) {
        let calendar = Calendar.current
        let dueStart = calendar.startOfDay(for: log.dueDate)
        let completedStart = calendar.startOfDay(for: log.createdAt)
        
        let diff = calendar.dateComponents([.day], from: dueStart, to: completedStart).day ?? 0
        
        if diff < 0 {
            return ("Early", .orange)
        } else if diff > 0 {
            return ("Late", .red)
        } else {
            return ("On time", .green)
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(task.symbolColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: task.sfSymbol ?? "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(task.symbolColor)
                    .brightness(-0.1)
                    .accessibilityHidden(true)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text("Cycle \(log.cycle)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
                
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
                
                Group {
                    Text(completionStatus.text)
                        .brightness(-0.1)
                }
                .font(.caption.bold())
                .foregroundStyle(completionStatus.color)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(completionStatus.color.opacity(0.15))
                .clipShape(Capsule())
            }
            .lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(task.name), for \(plant.name)")
        .accessibilityValue("Cycle \(log.cycle), completed \(viewModel.formatDate(log.createdAt)), \(completionStatus.text)")
    }
}
