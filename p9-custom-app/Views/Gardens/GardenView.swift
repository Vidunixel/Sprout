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
    
    var selectedGarden: Garden? {
        gardenStore.gardens.first(where: { $0.id == viewModel.selectedGardenId })
    }
    
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
            } else if selectedGarden != nil {
                // Plant grid
                if let plants = selectedGarden?.plants {
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
                            let latitude = selectedGarden?.geoLocation.first
                            ForEach(plants) { plant in
                                if let userId = authService.session?.user.id {
                                    NavigationLink {
                                        PlantDetailView(plantId: plant.id)
                                            .navigationTransition(.zoom(sourceID: plant.id, in: animationNamespace))
                                    } label: {
                                        PlantCardView(plant: plant, userId: userId, viewModel: viewModel, animationNamespace: animationNamespace, latitude: latitude)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(nil)
                                        
                                        Button(role: .destructive) {
                                            viewModel.plantToDelete = plant
                                            viewModel.showDeletePlantConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                        .foregroundStyle(.red)
                                        .disabled(viewModel.isLoading)
                                    }
                                    .confirmationDialog(
                                        "Delete Plant",
                                        isPresented: Binding(
                                            // Only show if showDeletePlantConfirmation is true and it matches this specific plant.
                                            get: { viewModel.showDeletePlantConfirmation && viewModel.plantToDelete?.id == plant.id },
                                            set: { isVisible in
                                                if !isVisible {
                                                    viewModel.showDeletePlantConfirmation = false
                                                    viewModel.plantToDelete = nil
                                                }
                                            }
                                        ),
                                        titleVisibility: .visible
                                    ) {
                                        Button("Delete", role: .destructive) {
                                            viewModel.deletePlant(plant: plant, plantStore: plantStore)
                                        }
                                        Button("Cancel", role: .cancel) {
                                            viewModel.plantToDelete = nil
                                        }
                                    } message: {
                                        Text("Are you sure you want to delete this plant?")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                    }
                    
                }
            } else {
                Text("Garden not found.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.showAddPlantView) {
            AddPlantView()
        }
        .sheet(isPresented: $viewModel.showAddGardenView) {
            AddGardenView()
        }
        .navigationTitle(selectedGarden?.city ?? "")
        .toolbar {
            if !gardenStore.gardens.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(gardenStore.gardens, id: \.self) { garden in
                            Button {
                                viewModel.selectedGardenId = garden.id
                            } label: {
                                if viewModel.selectedGardenId == garden.id {
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
                        Text(selectedGarden?.name ?? "Select Garden")
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
                .buttonStyle(.glassProminent)
            }
        }
        .appBackground()
        .onChange(of: gardenStore.gardens, initial: true) { _, newGardens in
            // If no garden is currently selected, or the currently selected garden was deleted.
            if viewModel.selectedGardenId == nil || !newGardens.contains(where: { $0.id == viewModel.selectedGardenId }) {
                // Default to the first available garden.
                viewModel.selectedGardenId = newGardens.first?.id
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

struct PlantCardView: View {
    let plant: Plant
    let userId: UUID
    let viewModel: GardenViewModel
    let animationNamespace: Namespace.ID
    let latitude: Double?
    
    // Calculate tasks that are due today (0) or overdue (< 0).
    var urgentTasksCount: Int {
        guard let tasks = plant.tasks else { return 0 }
        return tasks.filter { task in
            guard let days = task.daysUntilDue(latitude: latitude) else { return false }
            return days <= 0
        }.count
    }
    
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
            .matchedTransitionSource(id: plant.id, in: animationNamespace)
            .overlay(alignment: .bottomTrailing) {
                if urgentTasksCount > 0 {
                    Text("\(urgentTasksCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: -8, y: -8)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                }
            }
            
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
