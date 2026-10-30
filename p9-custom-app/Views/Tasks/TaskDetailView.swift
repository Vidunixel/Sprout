//
//  TaskDetailView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/10/2026.
//

import SwiftUI
import SceneKit

struct TaskDetailView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var gardenStore: GardenStore
    @EnvironmentObject private var taskLogStore: TaskLogStore
    
    let taskId: Int
    let plantId: Int
    var showPlantReference: Bool = false
    
    @State private var viewModel = TaskDetailViewModel()
    
    var task: TaskModel? {
        taskStore.tasks.first(where: { $0.id == taskId })
    }
    
    var plant: Plant? {
        plantStore.plants.first(where: { $0.id == plantId })
    }
    
    var garden: Garden? {
        guard let plant else { return nil }
        return gardenStore.gardens.first(where: { $0.id == plant.gardenId })
    }
    
    var latitude: Double? {
        if let garden {
           return garden.geoLocation.first
        }
        return nil
    }
    
    var body: some View {
        Group {
            if let task = task {
                List {
                    Section {
                        LabeledContent {
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
                                .font(.subheadline.bold())
                                .foregroundStyle(badgeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(badgeColor.opacity(0.15))
                                .clipShape(Capsule())
                            } else {
                                Text(task.dueStatusText(latitude: latitude))
                            }
                        } label: {
                            Text("Status")
                        }
                        
                        LabeledContent("Current Cycle", value: "\(task.currentCycle)")
                        
                        if !task.activeAdjustments.isEmpty {
                            LabeledContent("Weather Adjustments", value: task.appliedConditions)
                        }
                    } header: {
                        Text("Schedule")
                    } footer: {
                        if !task.activeAdjustments.isEmpty {
                            let combinedMultiplier = task.activeAdjustments.reduce(1.0) { $0 * $1.multiplier }
                                    
                            if combinedMultiplier < 1.0 {
                                Text("We’ve sped up the current shedule based on upcoming local weather forecasts.")
                            } else if combinedMultiplier > 1.0 {
                                Text("We’ve slowed down the current shedule based on upcoming local weather forecasts.")
                            } else {
                                Text("We’ve adjusted the current shedule based on upcoming local weather forecasts.")
                            }
                        }
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section {
                        LabeledContent {
                            Text(task.name)
                        } label: {
                            Text("Task")
                        }
                        
                        if showPlantReference, let plant {
                            NavigationLink {
                                PlantDetailView(plantId: plant.id)
                            } label: {
                                LabeledContent {
                                    HStack(spacing: 12) {
                                        Group {
                                            if let scene = viewModel.scene {
                                                PlantScene(scene: scene, yPadding: -0.1)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 5)
                                            } else if viewModel.isLoadingModel == true {
                                                ProgressView()
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            } else {
                                                Image(systemName: "leaf.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundStyle(.tertiary)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                        }
                                        .frame(width: 100, height: 100)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(plant.name)
                                                .font(.headline)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                            
                                            Text(plant.species)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                } label: {
                                    Text("Plant")
                                }
                            }
                            .task {
                                await viewModel.loadModel(for: plant)
                            }
                        }
                        
                        if let garden {
                            LabeledContent {
                                Text("\(garden.name) (\(garden.city))")
                            } label: {
                                Text("Garden")
                            }
                        }
                        
                        LabeledContent {
                            Text(task.instructions)
                        } label: {
                            Text("Instructions")
                        }
                    } header: {
                        Text("Details")
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section {
                        if let spring = task.springIntervalDays {
                            LabeledContent("Spring", value: "\(spring) days")
                        }
                        if let summer = task.summerIntervalDays {
                            LabeledContent("Summer", value: "\(summer) days")
                        }
                        if let autumn = task.autumnIntervalDays {
                            LabeledContent("Autumn", value: "\(autumn) days")
                        }
                        if let winter = task.winterIntervalDays {
                            LabeledContent("Winter", value: "\(winter) days")
                        }
                    } header: {
                        Text("Seasonal Frequency")
                    } footer: {
                        Text("How often this task repeats during different times of the year.")
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(task.name)
            } else {
                Text("Task not found.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showCompleteConfirmation = true }) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .confirmationDialog("Complete Task", isPresented: $viewModel.showCompleteConfirmation, titleVisibility: .visible) {
                    Button("Complete") {
                        if let currentTask = task {
                            viewModel.logTask(
                                task: currentTask,
                                dueDate: currentTask.dueDate(latitude: latitude),
                                taskLogStore: taskLogStore,
                                taskStore: taskStore
                            )
                        }
                    }
                } message: {
                    Text("Are you sure you want to log this task as complete for the current cycle?")
                }
            }
        }
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
