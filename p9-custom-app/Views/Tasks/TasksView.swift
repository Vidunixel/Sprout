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
    @EnvironmentObject private var taskLogStore: TaskLogStore
    
    @State private var viewModel = TasksViewModel()
    
    var body: some View {
        let urgent = viewModel.urgentTasks(tasks: taskStore.tasks, plants: plantStore.plants, gardens: gardenStore.gardens)
        let upcoming = viewModel.upcomingTasks(tasks: taskStore.tasks, plants: plantStore.plants, gardens: gardenStore.gardens)
        
        Group {
            if urgent.isEmpty && upcoming.isEmpty {
                Text("No tasks currently available.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !urgent.isEmpty {
                        Section("Urgent") {
                            ForEach(urgent) { task in
                                if let plant = plantStore.plants.first(where: { $0.id == task.plantId }) {
                                    let lat = viewModel.latitude(for: task, plants: plantStore.plants, gardens: gardenStore.gardens)
                                    NavigationLink(destination: TaskDetailView(taskId: task.id, plantId: plant.id, showPlantReference: true)) {
                                        TaskRowView(task: task, plant: plant, latitude: lat, viewModel: viewModel)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.taskToComplete = task
                                            viewModel.showCompleteConfirmation = true
                                        } label: {
                                            Label("Mark Complete", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                                    .confirmationDialog(
                                        "Complete Task",
                                        isPresented: Binding(
                                            // Only show if showCompleteConfirmation is true and it matches this specific task.
                                            get: { viewModel.showCompleteConfirmation && viewModel.taskToComplete?.id == task.id },
                                            set: { isVisible in
                                                if !isVisible {
                                                    viewModel.showCompleteConfirmation = false
                                                    viewModel.taskToComplete = nil
                                                }
                                            }
                                        ),
                                        titleVisibility: .visible
                                    ) {
                                        Button("Complete") {
                                            viewModel.logTask(
                                                task: task,
                                                dueDate: task.dueDate(latitude: lat),
                                                taskLogStore: taskLogStore,
                                                taskStore: taskStore
                                            )
                                        }
                                    } message: {
                                        Text("Are you sure you want to log this task as complete for the current cycle?")
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
                                    NavigationLink(destination: TaskDetailView(taskId: task.id, plantId: plant.id, showPlantReference: true)) {
                                        TaskRowView(task: task, plant: plant, latitude: lat, viewModel: viewModel)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.taskToComplete = task
                                            viewModel.showCompleteConfirmation = true
                                        } label: {
                                            Label("Mark Complete", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                                    .confirmationDialog(
                                        "Complete Task",
                                        isPresented: Binding(
                                            // Only show if showCompleteConfirmation is true and it matches this specific task.
                                            get: { viewModel.showCompleteConfirmation && viewModel.taskToComplete?.id == task.id },
                                            set: { isVisible in
                                                if !isVisible {
                                                    viewModel.showCompleteConfirmation = false
                                                    viewModel.taskToComplete = nil
                                                }
                                            }
                                        ),
                                        titleVisibility: .visible
                                    ) {
                                        Button("Complete") {
                                            viewModel.logTask(
                                                task: task,
                                                dueDate: task.dueDate(latitude: lat),
                                                taskLogStore: taskLogStore,
                                                taskStore: taskStore
                                            )
                                        }
                                    } message: {
                                        Text("Are you sure you want to log this task as complete for the current cycle?")
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.primary.opacity(0.05))
                    }
                }
                .listRowSeparator(.hidden)
                .listRowSpacing(12)
            }
            
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Tasks")
        .appBackground()
        .sensoryFeedback(.error, trigger: viewModel.feedbackTrigger)
        .alert("Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            let alertError = viewModel.errors.first(where: { $0.showAlert })
            Text(alertError?.localizedDescription ?? "An unknown error occurred.")
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { viewModel.errors.removeAll { $0.showAlert } } }
        )
    }
}

struct TaskRowView: View {
    let task: TaskModel
    let plant: Plant
    let latitude: Double?
    let viewModel: TasksViewModel
    
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
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text("Cycle \(task.currentCycle)")
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
                if let dueDate = task.dueDate(latitude: latitude) {
                    Text(viewModel.formatDate(dueDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                }
                
                let days = task.daysUntilDue(latitude: latitude) ?? 1
                if days <= 0 {
                    let isOverdue = days < 0
                    let badgeColor: Color = isOverdue ? .red : .orange
                    
                    HStack(spacing: 4) {
                        Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                            .brightness(-0.1)
                        Text(task.dueStatusText(latitude: latitude))
                            .brightness(-0.1)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())
                } else {
                    Text(task.dueStatusText(latitude: latitude))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                
                if !task.activeAdjustments.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                        Text("Weather adjusted")
                    }
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.secondary)
                    .clipShape(Capsule())
                }
            }
            .lineLimit(1)
        }
    }
}
