//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
import Supabase
import SceneKit

struct GardenView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var gardenStore: GardenStore
    
    @State private var viewModel = GardenViewModel()
    
    var body: some View {
        ZStack {
            if gardenStore.gardens.isEmpty {
                ScrollView {
                    VStack (spacing: 48) {
                        VStack(spacing: 24) {
                            Image(systemName: "carrot")
                                .font(.system(size: 100))
                                .foregroundStyle(.tint)
                            
                            Text("You don't have any gardens yet. Create one to get started.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Button(action: { viewModel.showAddGardenView = true }) {
                                Label("Create New", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
            } else {
                GardenSceneView().ignoresSafeArea()
            }
        }
        .sheet(isPresented: $viewModel.showAddPlantView) {
            AddPlantView()
        }
        .sheet(isPresented: $viewModel.showAddGardenView) {
            AddGardenView()
        }
        .navigationTitle("Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !gardenStore.gardens.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(gardenStore.gardens, id: \.self) { garden in
                            Button {
                                viewModel.selectedGarden = garden
                            } label: {
                                if viewModel.selectedGarden == garden {
                                    Image(systemName: "checkmark")
                                }
                                Text(garden.name)
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            viewModel.showAddGardenView = true
                        } label: {
                            Label("Create Garden", systemImage: "plus")
                        }
                        
                    } label: {
                        Text(viewModel.selectedGarden?.name ?? "Select Garden")
                            .font(.headline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                }
            }
            
            ToolbarItem(placement: .principal) {
                if let city = viewModel.selectedGarden?.city {
                    Text(city)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showAddPlantView = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .appBackground()
        .task {
            // Fetch db data.
            guard let userId = authService.session?.user.id else { return }
            await gardenStore.fetchGardens(for: userId)
            
            viewModel.setInitialGarden(gardenStore: gardenStore)
        }
    }
}

struct GardenSceneView: View {
    @State private var scene: SCNScene? = nil
    
    var body: some View {
        ZStack {
            if let scene = scene {
                GardenScene(
                    scene: scene,
                    ambientIntensity: 500,
                    sunIntensity: 1100
                )
                .transition(.opacity)
                
//                // Night
//                GardenScene(
//                    scene: scene,
//                    ambientIntensity: 120,
//                    sunIntensity: 150
//                )
//                .transition(.opacity)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading Garden...")
                        .foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            // Load the 3D model in the background.
            let loadedScene = await Task.detached(priority: .userInitiated) {
                SCNScene(named: "Garden.usdz")
            }.value
            
            await MainActor.run {
                withAnimation {
                    self.scene = loadedScene
                }
            }
        }
    }
}
