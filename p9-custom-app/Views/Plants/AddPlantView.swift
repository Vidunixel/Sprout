//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
import PhotosUI
import Supabase

enum FormStage: Int, CaseIterable {
    case photo = 0
    case species = 1
    case name = 2
    case locationLight = 3
    case pot = 4
    case garden = 5
}

struct AddPlantView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var gardenStore: GardenStore
    
    @State private var viewModel = AddPlantViewModel()
    
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 8) {
                    Text("\(String(viewModel.currentStage.rawValue + 1)).")
                        .font(.title3.bold())
                    
                    Text(currentPageTitle)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Progress bar.
                ProgressView(
                    value: Double(viewModel.currentStage.rawValue + 1),
                    total: Double(FormStage.allCases.count)
                )
            }
            .padding(.top, 40)
            .padding(.horizontal, 28)
            
            Spacer()
            
            ZStack {
                Group {
                    switch viewModel.currentStage {
                    case .photo:
                        PhotoPage(viewModel: viewModel, showCamera: $showCamera, photoItem: $photoItem)
                    case .species:
                        SpeciesPage(viewModel: viewModel)
                    case .name:
                        NamePage(viewModel: viewModel)
                    case .locationLight:
                        LocationLightPage(viewModel: viewModel)
                    case .pot:
                        PotPage(viewModel: viewModel)
                    case .garden:
                        GardenPage(viewModel: viewModel)
                    }
                }
            }
            
            HStack {
                if viewModel.currentStage != .photo {
                    Button(action: viewModel.previousStage) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.backward")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Button(action: {
                    if viewModel.currentStage == .garden {
                        viewModel.nextStage(submit: true)
                    } else {
                        viewModel.nextStage()
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        if viewModel.currentStage == .garden {
                            Text("Submit")
                        } else {
                            Text("Next").frame(maxWidth: .infinity)
                            Image(systemName: "arrow.forward")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
            }
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $viewModel.photoImage)
        }
        .navigationTitle("Add Plant")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
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
    
    private var currentPageTitle: String {
        switch viewModel.currentStage {
        case .photo:
            return "Upload a photo of your plant"
        case .species:
            return "Select plant species"
        case .name:
            return "Give your plant a name"
        case .locationLight:
            return "Your plant’s environment"
        case .pot:
            return "Your plant’s pot size"
        case .garden:
            return "Select your garden"
        }
    }
}

private struct PageView<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                content()
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
    }
}

private struct PhotoPage: View {
    var viewModel: AddPlantViewModel
    @Binding var showCamera: Bool
    @Binding var photoItem: PhotosPickerItem?
    
    var body: some View {
        PageView {
            if let photoImage = viewModel.photoImage {
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 100))
                    .foregroundStyle(.tint)
            }
            
            VStack(spacing: 14) {
                Button(action: { showCamera = true }) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
                
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Select Photo", systemImage: "photo.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .controlSize(.large)
                .onChange(of: photoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            viewModel.photoImage = uiImage
                        }
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
    }
}

private struct SpeciesPage: View {
    @Bindable var viewModel: AddPlantViewModel
    
    var body: some View {
        PageView {
            VStack(alignment: .leading, spacing: 14) {
                Section {
                    ForEach(viewModel.identifiedPlants, id: \.self) { plant in
                        Button(action: { viewModel.selectPlantSpecies(plant: plant) }) {
                            HStack(alignment: .top, spacing: 12) {
                                if let url = plant.images.first?.url.m {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case let .success(image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 70, height: 70)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                            
                                        case .failure:
                                            coverPlaceholder
                                            
                                        @unknown default:
                                            coverPlaceholder
                                        }
                                    }
                                } else {
                                    coverPlaceholder
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plant.species.scientificNameWithoutAuthor)
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    if !plant.species.commonNames.isEmpty {
                                        Text(plant.species.commonNames.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: viewModel.selectedSpecies?.id == plant.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.selectedSpecies?.id == plant.id ? Color.accentColor : Color.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Select")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                }
                
                Divider().padding(.vertical, 8)
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            TextField("e.g., Lavender", text: $viewModel.species)
                                .frame(height: 54)
                                .padding(.horizontal, 16)
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(999)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                                .onChange(of: viewModel.species) { oldValue, newValue in
                                    if !newValue.isEmpty {
                                        viewModel.selectedSpecies = nil
                                    }
                                }
                            
                            Image(systemName: !viewModel.species.isEmpty ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(!viewModel.species.isEmpty ? Color.accentColor : Color.secondary)
                        }
                    }
                } header: {
                    Text("Enter Manually")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var coverPlaceholder: some View {
        Image(systemName: "camera.macro")
            .font(.system(size: 30))
            .foregroundStyle(Color(uiColor: .systemGray3))
            .frame(width: 50, height: 50)
    }
}

private struct NamePage: View {
    @Bindable var viewModel: AddPlantViewModel
    
    var body: some View {
        PageView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    
                    let nameField = TextField("Enter a name", text: $viewModel.name)
                        .frame(height: 54)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(999)
                    
                    let targetErrors = ["name_empty"]
                    if let nameError = viewModel.errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                        nameField
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color(uiColor: .systemRed), lineWidth: 2)
                            )
                        
                        Text("*\(nameError.localizedDescription)")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    } else {
                        nameField
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
}

private struct LocationLightPage: View {
    @Bindable var viewModel: AddPlantViewModel
    
    var body: some View {
        PageView {
            VStack(alignment: .leading, spacing: 14) {
                Section() {
                    Picker("Location", selection: $viewModel.isIndoors) {
                        Text("Indoors").tag(true)
                        Text("Outdoors").tag(false)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Location")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                }
                
                Divider().padding(.vertical, 8)
                
                Section() {
                    Picker("Light Exposure", selection: $viewModel.lightExposure) {
                        ForEach(AddPlantViewModel.PlantLightExposure.allCases) {
                            switch $0 {
                            case .low:
                                Text("Low").tag($0)
                            case .medium:
                                Text("Medium").tag($0)
                            case .high:
                                Text("High").tag($0)
                            }
                        }
                    }
                    .pickerStyle(.wheel)
                } header: {
                    Text("Light Exposure")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct PotPage: View {
    @Bindable var viewModel: AddPlantViewModel
    
    var body: some View {
        PageView {
            VStack(alignment: .leading, spacing: 14) {
                Section() {
                    Picker("Pot Size", selection: $viewModel.potSize) {
                        Text("(None)").tag(nil as AddPlantViewModel.PotSize?)
                        ForEach(AddPlantViewModel.PotSize.allCases) {
                            switch $0 {
                            case .mini:
                                Text("Mini (2–4\" wide)").tag($0)
                            case .small:
                                Text("Small (5–7\" wide)").tag($0)
                            case .medium:
                                Text("Medium (8–12\" wide)").tag($0)
                            case .large:
                                Text("Large (13\"+ wide)").tag($0)
                            }
                        }
                    }
                    .pickerStyle(.wheel)
                } header: {
                    Text("Pot Size")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct GardenPage: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var gardenStore: GardenStore
    
    @Bindable var viewModel: AddPlantViewModel
    @State private var showAddGardenView = false
    
    var body: some View {
        PageView {
            Image(systemName: "carrot")
                .font(.system(size: 100))
                .foregroundStyle(.tint)
            
            VStack(alignment: .leading, spacing: 24) {
                if !gardenStore.gardens.isEmpty {
                    ForEach(gardenStore.gardens, id: \.self) { garden in
                        Button(action: { viewModel.garden = garden }) {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(garden.name)
                                        .font(.headline)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text(garden.city)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: viewModel.garden?.id == garden.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.garden?.id == garden.id ? Color.accentColor : Color.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("You don't have any gardens yet. Create one to get started.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: { showAddGardenView = true }) {
                    Label("Create New", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .task {
            // Fetch db data.
            guard let userId = authService.session?.user.id else { return }
            await gardenStore.fetchGardens(for: userId)
        }
        .sheet(isPresented: $showAddGardenView) {
            AddGardenView()
        }
    }
}
