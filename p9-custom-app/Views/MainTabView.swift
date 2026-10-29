//
//  MainTabView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 29/9/2026.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var gardenStore: GardenStore
    
    var urgentTasksCount: Int {
            taskStore.tasks.filter { task in
                let lat = latitude(for: task)
                let days = task.daysUntilDue(latitude: lat) ?? 1
                return days <= 0
            }.count
        }
    
    private func latitude(for task: TaskModel) -> Double? {
        guard let plant = plantStore.plants.first(where: { $0.id == task.plantId }),
              let garden = gardenStore.gardens.first(where: { $0.id == plant.gardenId }) else { return nil }
        return garden.geoLocation.first
    }
    
    var body: some View {
        TabView {
            NavigationStack {
                GardenView()
            }
            .tabItem { Label("Garden", systemImage: "carrot") }
            
            NavigationStack {
                TasksView()
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }
            .badge(urgentTasksCount)
            
            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock") }
            
            NavigationStack {
                AccountView()
            }
            .tabItem { Label("Account", systemImage: "person") }
        }
    }
}
