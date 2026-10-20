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
    
    @State private var showUpdatePasswordView = false
    
    var body: some View {
        Group {
            if authService.session != nil {
                MainTabView()
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
        .sheet(isPresented: $showUpdatePasswordView) {
            UpdatePasswordView()
        }
        .onOpenURL { url in
            // Catch deeplink for supabase auth redirect.
            if url.host == "auth" {
                Task {
                    do {
                        // Log user in
                        try await supabase.auth.session(from: url)
                        
                        if url.path == "/reset-password" {
                            showUpdatePasswordView = true
                        }
                    } catch {
                        print("Auth error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
