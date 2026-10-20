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
    
    @Namespace private var animationNamespace
    
    let columns = [
        GridItem(.flexible(), spacing: 16, alignment: .top),
        GridItem(.flexible(), spacing: 16, alignment: .top)
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
                .containerRelativeFrame(.vertical)
            } else {
                // Plant grid
                if let plants = viewModel.selectedGarden?.plants {
                    if plants.isEmpty {
                        VStack (spacing: 48) {
                            VStack(spacing: 24) {
                                Image(uiImage: .plant)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .clipped()
                                
                                Text("This garden is empty. Start by adding a plant.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            VStack(alignment: .leading, spacing: 14) {
                                Button(action: { viewModel.showAddPlantView = true }) {
                                    Label("Add a Plant", systemImage: "plus")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                        .padding(28)
                        .containerRelativeFrame(.vertical)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(plants) { plant in
                                if let userId = authService.session?.user.id {
                                    NavigationLink {
                                        PlantDetailView(plant: plant, gardenViewModel: viewModel)
                                            .navigationTransition(.zoom(sourceID: plant.id, in: animationNamespace))
                                    } label: {
                                        PlantCardView(plant: plant, userId: userId, viewModel: viewModel)
                                            .matchedTransitionSource(id: plant.id, in: animationNamespace)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
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
        .navigationTitle(viewModel.selectedGarden?.city ?? "")
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showAddPlantView = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .appBackground()
        .task {
            // Fetch db data.
            guard let userId = authService.session?.user.id else { return }
            await gardenStore.fetchGardens(for: userId)
            
            viewModel.setInitialGarden(gardenStore: gardenStore)
        }
        .onChange(of: gardenStore.gardens) { _, updatedGardens in
            if let currentSelectedGardenId = viewModel.selectedGarden?.id {
                viewModel.selectedGarden = updatedGardens.first(where: { $0.id == currentSelectedGardenId })
            } else {
                viewModel.setInitialGarden(gardenStore: gardenStore)
            }
        }
    }
}

struct PlantCardView: View {
    let plant: Plant
    let userId: UUID
    let viewModel: GardenViewModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center) {
                if let scene = viewModel.plantScenes[plant.id] {
                    PlantScene(scene: scene, yPadding: -0.1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 5)
                } else if viewModel.plantLoadingStates[plant.id] == true {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 175)
            
            VStack(alignment: .center, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(plant.species)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 10)
        .task {
            await viewModel.loadPlantModel(for: plant, userId: userId)
        }
    }
}
