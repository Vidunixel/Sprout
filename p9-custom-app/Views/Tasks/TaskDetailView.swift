//
//  TaskDetailView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/10/2026.
//

import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var gardenStore: GardenStore
    @EnvironmentObject private var taskLogStore: TaskLogStore
    
    let taskId: Int
    let plantId: Int
    
    @State private var viewModel = TaskDetailViewModel()
    
    var task: TaskModel? {
        taskStore.tasks.first(where: { $0.id == taskId })
    }
    
    var latitude: Double? {
        if let plant = plantStore.plants.first(where: { $0.id == plantId }),
           let garden = gardenStore.gardens.first(where: { $0.id == plant.gardenId }) {
            return garden.geoLocation.first
        }
        return nil
    }
    
    var activeAdjustments: [WeatherAdjustment] {
        guard let task = task, let adjustments = task.weatherAdjustments else { return [] }
        return adjustments.filter { adjustment in
            adjustment.timelines?.contains(where: { $0.cycle == task.currentCycle }) ?? false
        }
    }
    
    var appliedConditions: String {
        activeAdjustments.map { adjustment in
            switch adjustment.name {
            case "heavyRainMultiplier": return "Heavy Rain"
            case "extremeHeatMultiplier": return "Extreme Heat"
            default: return adjustment.name
            }
        }.joined(separator: ", ")
    }
    
    var body: some View {
        Group {
            if let task = task {
                List {
                    Section {
                        LabeledContent {
                            Text(task.name)
                        } label: {
                            Text("Task")
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
                        LabeledContent {
                            let days = task.daysUntilDue(latitude: latitude) ?? 1
                            Text(task.dueStatusText(latitude: latitude))
                                .foregroundStyle(days < 0 ? .red : (days == 0 ? .orange : .secondary))
                        } label: {
                            Text("Status")
                        }
                        
                        LabeledContent("Current Cycle", value: "\(task.currentCycle)")
                        
                        if !activeAdjustments.isEmpty {
                            LabeledContent("Weather Adjustments", value: appliedConditions)
                        }
                    } header: {
                        Text("Schedule")
                    } footer: {
                        if !activeAdjustments.isEmpty {
                            let combinedMultiplier = activeAdjustments.reduce(1.0) { $0 * $1.multiplier }
                                    
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
