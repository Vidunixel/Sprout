//
//  ContentView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Supabase

struct RootView: View {
    @Environment(\.scenePhase) var scenePhase
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
            if authService.isInitialising {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
                .ignoresSafeArea()
            } else if authService.session != nil {
                MainTabView()
                    .overlay {
                        if viewModel.isBooting {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .controlSize(.large)
                                Text("Loading...")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.background)
                            .ignoresSafeArea()
                        }
                    }
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
        .onChange(of: authService.session) { _, newSession in
            if newSession == nil {
                Task { await viewModel.cleanup() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && !viewModel.isBooting {
                if let userId = authService.session?.user.id {
                    Task {
                        await viewModel.syncAllData(
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
            }
        }
        .onChange(of: taskStore.tasks) { _, _ in
            if !viewModel.isBooting {
                NotificationService.shared.syncNotifications(
                    tasks: taskStore.tasks,
                    plants: plantStore.plants,
                    gardens: gardenStore.gardens
                )
            }
        }
    }
}
