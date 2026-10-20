//
//  ContentView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Supabase

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var gardenStore = GardenStore()
    @StateObject private var plantStore = PlantStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var taskLogStore = TaskLogStore()
    @StateObject private var weatherAdjustmentStore = WeatherAdjustmentStore()
    @StateObject private var weatherAdjustmentTimelineStore = WeatherAdjustmentTimelineStore()
    
    @State private var viewModel = RootViewModel()
    
    var body: some View {
        Group {
            if authService.session != nil {
                MainTabView()
                    .task {
                        if let userId = authService.session?.user.id {
                            await viewModel.performBootTasks(
                                userId: userId,
                                gardenStore: gardenStore,
                                plantStore: plantStore,
                                taskLogStore: taskLogStore,
                                taskStore: taskStore,
                                weatherAdjustmentStore: weatherAdjustmentStore,
                                weatherAdjustmentTimelineStore: weatherAdjustmentTimelineStore
                            )
                        }
                    }
            } else {
                AuthenticationView()
            }
        }
        .environmentObject(gardenStore)
        .environmentObject(plantStore)
        .environmentObject(taskStore)
        .environmentObject(taskLogStore)
        .environmentObject(weatherAdjustmentStore)
        .environmentObject(weatherAdjustmentTimelineStore)
        .sheet(isPresented: $viewModel.showUpdatePasswordView) {
            UpdatePasswordView()
        }
        .onOpenURL { url in
            viewModel.handleOpenURL(url)
        }
    }
}
