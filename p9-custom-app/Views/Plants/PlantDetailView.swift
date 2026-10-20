//
//  DetailedPlantView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 18/10/2026.
//

import SwiftUI

struct PlantDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var gardenViewModel: GardenViewModel
    @State private var viewModel: PlantDetailViewModel
    @State private var showPanel = true
    
    init(plant: Plant, gardenViewModel: GardenViewModel) {
        self._gardenViewModel = State(wrappedValue: gardenViewModel)
        self._viewModel = State(wrappedValue: PlantDetailViewModel(plant: plant))
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                if let scene = gardenViewModel.plantScenes[viewModel.plant.id] {
                    PlantScene(scene: scene, allowHorizontalRotation: true, autoRotate: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 5)
                } else if gardenViewModel.plantLoadingStates[viewModel.plant.id] == true {
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
        .disableBackSwipe()
        .appBackground()
        .navigationTitle(viewModel.plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPanel) {
            PlantDetailPanelView(viewModel: viewModel, executeDismissal: executeDismissal)
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled()
                .presentationBackgroundInteraction(.enabled)
        }
    }
    
    private func executeDismissal() {
        showPanel = false
        dismiss()
    }
}

struct PlantDetailPanelView: View {
    @EnvironmentObject private var gardenStore: GardenStore
    @Bindable var viewModel: PlantDetailViewModel
    
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
                            Text(viewModel.plant.name)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            
                            Text(viewModel.plant.species)
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
                    let garden = gardenStore.gardens.first(where: { $0.id == viewModel.plant.gardenId })
                    let latitude = garden?.geoLocation.first
                    
                    if let tasks = viewModel.plant.tasks, !tasks.isEmpty {
                        ForEach(tasks, id: \.self) { task in
                            NavigationLink {
                            } label: {
                                HStack {
                                    Text(task.name)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(task.dueStatusText(latitude: latitude))
                                        .foregroundStyle((task.daysUntilDue(latitude: latitude) ?? 1) < 0 ? .red : .secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Text("None")
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Tasks")
                }
                .listRowBackground(
                    Color.primary.opacity(0.05)
                )
                
                Section {
                    HStack {
                        Text("Garden")
                        Spacer()
                        
                        if let garden = gardenStore.gardens.first(where: { $0.id == viewModel.plant.gardenId }) {
                            Text("\(garden.name) (\(garden.city))")
                                .foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("Light Exposure")
                        Spacer()
                        
                        switch viewModel.plant.lightExposure {
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
                    }
                    HStack {
                        Text("Pot Size")
                        Spacer()
                        
                        switch viewModel.plant.potSize {
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
                    }
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(viewModel.plant.isIndoors ? "Indoors" : "Outdoors")
                            .foregroundColor(.gray)
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
                        HStack(spacing: 4) {
                            Image(systemName: "xmark").fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .appBackground()
        .task {
            await viewModel.loadImage()
        }
    }
}
