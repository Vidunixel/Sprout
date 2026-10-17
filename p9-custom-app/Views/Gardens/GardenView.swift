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
    @EnvironmentObject private var plantStore: PlantStore
        
    @State private var viewModel = GardenViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            if gardenStore.gardens.isEmpty {
                VStack (spacing: 48) {
                    VStack(spacing: 24) {
                        Image(uiImage: .carrot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .clipped()
                        
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
            } else {
                // Plant grid
                if let plants = viewModel.selectedGarden?.plants {
                    if plants.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "leaf")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("This garden is empty.")
                                .foregroundStyle(.secondary)
                            Button("Add a Plant") {
                                viewModel.showAddPlantView = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(plants) { plant in
                                if let userId = authService.session?.user.id {
                                    PlantCardView(plant: plant, userId: userId, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(20)
                    }
                    
                }
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

struct PlantCardView: View {
    let plant: Plant
    let userId: UUID
    let viewModel: GardenViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Color(uiColor: .secondarySystemFill)
                    .cornerRadius(12)
                
                if let scene = viewModel.plantScenes[plant.id] {
                    SceneView(
                        scene: scene,
                        options: [.autoenablesDefaultLighting, .allowsCameraControl]
                    )
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if viewModel.plantLoadingStates[plant.id] == true {
                    ProgressView()
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 140)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(plant.species)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .padding(10)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .task {
            // Download model.
            await viewModel.loadPlantModel(for: plant, userId: userId)
        }
    }
}
