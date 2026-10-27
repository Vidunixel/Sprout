//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var gardenStore: GardenStore
    
    @State private var viewModel = TasksViewModel()
    
    var body: some View {
        List {
            let urgent = viewModel.urgentTasks(tasks: taskStore.tasks, plants: plantStore.plants, gardens: gardenStore.gardens)
            let upcoming = viewModel.upcomingTasks(tasks: taskStore.tasks, plants: plantStore.plants, gardens: gardenStore.gardens)
            
            if !urgent.isEmpty {
                Section("Urgent") {
                    ForEach(urgent) { task in
                        if let plant = plantStore.plants.first(where: { $0.id == task.plantId }) {
                            let lat = viewModel.latitude(for: task, plants: plantStore.plants, gardens: gardenStore.gardens)
                            NavigationLink(destination: TaskDetailView(taskId: task.id, plantId: plant.id)) {
                                TaskRowView(task: task, plant: plant, latitude: lat)
                            }
                        }
                    }
                }
                .listRowBackground(Color.primary.opacity(0.05))
            }
            
            if !upcoming.isEmpty {
                Section("Upcoming") {
                    ForEach(upcoming) { task in
                        if let plant = plantStore.plants.first(where: { $0.id == task.plantId }) {
                            let lat = viewModel.latitude(for: task, plants: plantStore.plants, gardens: gardenStore.gardens)
                            NavigationLink(destination: TaskDetailView(taskId: task.id, plantId: plant.id)) {
                                TaskRowView(task: task, plant: plant, latitude: lat)
                            }
                        }
                    }
                }
                .listRowBackground(Color.primary.opacity(0.05))
            }
            
            if urgent.isEmpty && upcoming.isEmpty {
                Text("No tasks currently available.")
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Tasks")
        .appBackground()
    }
}

struct TaskRowView: View {
    let task: TaskModel
    let plant: Plant
    let latitude: Double?
    
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
            
            let days = task.daysUntilDue(latitude: latitude) ?? 1
            Text(task.dueStatusText(latitude: latitude))
                .font(.caption.bold())
                .foregroundStyle(days < 0 ? .red : (days == 0 ? .orange : .secondary))
                .multilineTextAlignment(.trailing)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .containerRelativeFrame(.horizontal, alignment: .trailing) { length, _ in
                    //15% of container.
                    length * 0.15
                }
        }
    }
}
