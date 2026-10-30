//
//  DetailedPlantView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 18/10/2026.
//

import SwiftUI

struct PlantDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var plantStore: PlantStore
    
    let plantId: Int
    @State private var viewModel = PlantDetailViewModel()
    @State private var showPanel = true
    
    var plant: Plant? {
        plantStore.plants.first(where: { $0.id == plantId })
    }
    
    var body: some View {
        Group {
            if let plant {
                GeometryReader { geo in
                    VStack(alignment: .center) {
                        if let scene = viewModel.scene {
                            PlantScene(scene: scene, allowHorizontalRotation: true, autoRotate: true)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 5)
                        } else if viewModel.isLoadingModel == true {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.5)
                }
                .navigationTitle(plant.name)
                .sheet(isPresented: $showPanel) {
                    PlantDetailPanelView(viewModel: viewModel, plant: plant, executeDismissal: executeDismissal)
                        .presentationDetents([.medium, .large])
                        .interactiveDismissDisabled()
                        .presentationBackgroundInteraction(.enabled)
                }
                .task {
                    await viewModel.loadModel(for: plant)
                }
            } else {
                Text("Plant not found.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .disableBackSwipe(plant == nil ? false : true)
        .appBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(plant == nil ? false : true)
    }
    
    private func executeDismissal() {
        showPanel = false
        dismiss()
    }
}

struct PlantDetailPanelView: View {
    @EnvironmentObject private var gardenStore: GardenStore
    @EnvironmentObject private var plantStore: PlantStore
    @Bindable var viewModel: PlantDetailViewModel
    let plant: Plant
    
    var executeDismissal: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        if let uiImage = viewModel.uiImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else if viewModel.isLoadingImage {
                            ProgressView()
                                .frame(width: 60, height: 60)
                        } else {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.tertiary)
                                .frame(width: 60, height: 60)
                                .background(Color(uiColor: .systemGray6))
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plant.name)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            
                            Text(plant.species)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .listRowBackground(
                    Color.primary.opacity(0.05)
                )
                
                Section {
                    let garden = gardenStore.gardens.first(where: { $0.id == plant.gardenId })
                    let latitude = garden?.geoLocation.first
                    
                    if let tasks = plant.tasks, !tasks.isEmpty {
                        ForEach(tasks, id: \.self) { task in
                            NavigationLink {
                                TaskDetailView(taskId: task.id, plantId: plant.id)
                            } label: {
                                let days = task.daysUntilDue(latitude: latitude) ?? 1
                                LabeledContent {
                                    if days <= 0 {
                                        let isOverdue = days < 0
                                        let badgeColor: Color = isOverdue ? .red : .orange
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                                                .brightness(-0.1)
                                            Text(task.dueStatusText(latitude: latitude))
                                                .brightness(-0.1)
                                        }
                                        .font(.subheadline.bold())
                                        .foregroundStyle(badgeColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(badgeColor.opacity(0.15))
                                        .clipShape(Capsule())
                                    } else {
                                        Text(task.dueStatusText(latitude: latitude))
                                    }
                                } label: {
                                    Text(task.name)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } else {
                        Text("None")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("Tasks")
                }
                .listRowBackground(
                    Color.primary.opacity(0.05)
                )
                
                Section {
                    LabeledContent {
                        if let garden = gardenStore.gardens.first(where: { $0.id == plant.gardenId }) {
                            Text("\(garden.name) (\(garden.city))")
                                .foregroundColor(.gray)
                        }
                    } label: {
                        Text("Garden")
                    }
                    
                    LabeledContent {
                        switch plant.lightExposure {
                        case .low:
                            Text("Low")
                                .foregroundColor(.gray)
                        case .medium:
                            Text("Medium")
                                .foregroundColor(.gray)
                        case .high:
                            Text("High")
                                .foregroundColor(.gray)
                        }
                    } label: {
                        Text("Light Exposure")
                    }
                    
                    LabeledContent {
                        switch plant.potSize {
                        case .mini:
                            Text("Mini (2–4\" wide)")
                                .foregroundColor(.gray)
                        case .small:
                            Text("Small (5–7\" wide)")
                                .foregroundColor(.gray)
                        case .medium:
                            Text("Medium (8–12\" wide)")
                                .foregroundColor(.gray)
                        case .large:
                            Text("Large (13\"+ wide)")
                                .foregroundColor(.gray)
                        default:
                            Text("None")
                                .foregroundColor(.gray)
                        }
                    } label: {
                        Text("Pot Size")
                    }
                    
                    LabeledContent {
                        Text(plant.isIndoors ? "Indoors" : "Outdoors")
                            .foregroundColor(.gray)
                    } label: {
                        Text("Location")
                    }
                } header: {
                    Text("Plant Details")
                }
                .listRowBackground(
                    Color.primary.opacity(0.05)
                )
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        executeDismissal()
                    } label: {
                        Image(systemName: "xmark").fontWeight(.semibold)
                    }
                    .tint(nil)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.showDeletePlantConfirmation = true
                    } label: {
                        Image(systemName: "trash").fontWeight(.semibold)
                    }
                    .disabled(viewModel.isLoading)
                    .confirmationDialog(
                        "Delete Plant",
                        isPresented: $viewModel.showDeletePlantConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            viewModel.deletePlant(plant: plant, plantStore: plantStore)
                        }
                    } message: {
                        Text("Are you sure you want to delete this plant?")
                    }
                }
            }
        }
        .appBackground()
        .task {
            await viewModel.loadImage(for: plant)
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
