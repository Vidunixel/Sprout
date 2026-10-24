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
    
    let taskId: Int
    let plantId: Int
    
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
                        Text(task.instructions)
                            .font(.body)
                    } header: {
                        Text("Instructions")
                    }
                    .listRowBackground(Color.primary.opacity(0.05))
                    
                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(task.dueStatusText(latitude: latitude))
                                .foregroundStyle((task.daysUntilDue(latitude: latitude) ?? 1) < 0 ? .red : .secondary)
                        }
                        
                        HStack {
                            Text("Current Cycle")
                            Spacer()
                            Text("\(task.currentCycle)")
                                .foregroundStyle(.secondary)
                        }
                        
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
    }
}
