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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var gardenStore: GardenStore
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var weatherAdjustmentStore: WeatherAdjustmentStore
    
    @State private var viewModel = AddPlantViewModel()
    
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
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
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $viewModel.photoImage)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Progress bar.
                    ProgressView(
                        value: Double(viewModel.currentStage.rawValue + 1),
                        total: Double(FormStage.allCases.count)
                    )
                    .accessibilityLabel("Form progress")
                    .accessibilityValue("Step \(viewModel.currentStage.rawValue + 1) of \(FormStage.allCases.count)")
                    .frame(width: 300, height: 6)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if viewModel.currentStage != .photo {
                        Button(action: viewModel.previousStage) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.backward")
                            }
                        }
                        .accessibilityLabel("Previous step")
                        .accessibilityHint("Returns to the previous form step")
                        .disabled(viewModel.isLoading)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.currentStage == .garden {
                            viewModel.nextStage(
                                submit: true,
                                authService: authService,
                                plantStore: plantStore,
                                taskStore: taskStore,
                                weatherAdjustmentStore: weatherAdjustmentStore
                            )
                        } else {
                            viewModel.nextStage()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            if viewModel.currentStage == .garden {
                                Text("Submit")
                            } else {
                                Text("Next").frame(maxWidth: .infinity)
                                Image(systemName: "arrow.forward")
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel(viewModel.currentStage == .garden ? "Submit" : "Next step")
                    .accessibilityValue(viewModel.isLoading ? "In progress" : "")
                    .accessibilityHint(viewModel.currentStage == .garden ? "Submits the plant information" : "Proceeds to next step")
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 8)
                }
            }
            .appBackground()
            .sensoryFeedback(.error, trigger: viewModel.feedbackTrigger)
            .alert("Error", isPresented: errorIsPresented) {
                Button("OK", role: .cancel) { }
            } message: {
                let alertError = viewModel.errors.first(where: { $0.showAlert })
                Text(alertError?.localizedDescription ?? "An unknown error occurred.")
            }
            .onChange(of: viewModel.dismissView) { _, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { viewModel.errors.removeAll { $0.showAlert } } }
        )
    }
}

private struct PageView<Content: View>: View {
    var pageNumber: Int?
    var pageTitle: String
    var shouldAddTitleMargin: Bool = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ScrollView {
            VStack (spacing: titleSpacing) {
                HStack(alignment: .top, spacing: 8) {
                    if let pageNumber = pageNumber {
                        Text("\(pageNumber).")
                            .font(.title2.bold())
                    }

                    Text(pageTitle)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack (spacing: 48) {
                    content()
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
    }
    
    var titleSpacing: Double {
        return shouldAddTitleMargin ? 48 : 14
    }
}

private struct PhotoPage: View {
    var viewModel: AddPlantViewModel
    @Binding var showCamera: Bool
    @Binding var photoItem: PhotosPickerItem?
    
    var body: some View {
        PageView(pageNumber: 1, pageTitle: "Upload a photo of your plant", shouldAddTitleMargin: true) {
            if let photoImage = viewModel.photoImage {
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
                    .accessibilityLabel("Selected plant photo")
            } else {
                Image(uiImage: .camera)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .clipped()
                    .accessibilityHidden(true)
            }
            
            VStack(spacing: 14) {
                Button(action: { showCamera = true }) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityHint("Opens camera to take a photo of your plant")
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isLoading)
                
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Select Photo", systemImage: "photo.fill")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityHint("Opens photo library to choose a plant photo")
                .buttonStyle(.bordered)
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
        PageView(pageNumber: 2, pageTitle: "Select plant species") {
            VStack(alignment: .leading, spacing: 14) {
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
                                            .frame(width: 70, height: 70)
                                        
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
                                    .lineLimit(2)
                                
                                if !plant.species.commonNames.isEmpty {
                                    Text(plant.species.commonNames.joined(separator: ", "))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: viewModel.selectedSpecies?.id == plant.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.selectedSpecies?.id == plant.id ? Color.accentColor : Color.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(plant.species.scientificNameWithoutAuthor)
                    .accessibilityValue(plant.species.commonNames.joined(separator: ", "))
                    .accessibilityAddTraits(viewModel.selectedSpecies?.id == plant.id ? [.isSelected] : [])
                    .accessibilityHint("Selects \(plant.species.scientificNameWithoutAuthor) as the species")
                    .buttonStyle(.plain)
                    
                    // Divider between rows
                    Divider()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Other")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    
                    HStack(spacing: 4) {
                        CustomField {
                            TextField("e.g., Lavender", text: $viewModel.species)
                                .onChange(of: viewModel.species) { oldValue, newValue in
                                    if !newValue.isEmpty {
                                        viewModel.selectedSpecies = nil
                                    }
                                }
                                .padding(.horizontal, 6)
                                .accessibilityLabel("Other species name")
                        }
                        
                        Image(systemName: !viewModel.species.isEmpty ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(!viewModel.species.isEmpty ? Color.accentColor : Color.secondary)
                    }
                }
            }
        }
    }
    
    private var coverPlaceholder: some View {
        Image(systemName: "camera.macro")
            .font(.system(size: 30))
            .foregroundStyle(Color(uiColor: .systemGray3))
            .frame(width: 50, height: 50)
            .accessibilityHidden(true)
    }
}

private struct NamePage: View {
    @Bindable var viewModel: AddPlantViewModel
    
    var body: some View {
        PageView(pageNumber: 3, pageTitle: "Give your plant a name") {
            VStack(spacing: 14) {
                CustomField(
                    errors: viewModel.errors,
                    targetErrorCodes: ["name_empty"]
                ) {
                    TextField("Enter a name", text: $viewModel.name)
                        .padding(.horizontal, 6)
                        .accessibilityLabel("Plant nickname")
                }
            }
        }
    }
}

private struct LocationLightPage: View {
    @Bindable var viewModel: AddPlantViewModel
    
    var body: some View {
        PageView(pageNumber: 4, pageTitle: "Your plant’s environment?") {
            VStack(alignment: .leading, spacing: 14) {
                Section {
                    HStack(spacing: 16) {
                        // Indoors Option
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.isIndoors = true
                            }
                        }) {
                            VStack(spacing: 12) {
                                Image(uiImage: .house)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 80)
                                    .scaleEffect(viewModel.isIndoors ? 1.15 : 1.0)
                                    .accessibilityHidden(true)
                                
                                Text("Indoors")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(viewModel.isIndoors ? .primary : .secondary)
                                
                                Image(systemName: viewModel.isIndoors ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(viewModel.isIndoors ? Color.accentColor : Color.secondary)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle()) // Ensures the whole area is tappable
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Indoors")
                        .accessibilityAddTraits(viewModel.isIndoors ? [.isSelected] : [])
                        .accessibilityHint("Sets plant environment to indoors")
                        .buttonStyle(.plain)
                        
                        // Outdoors Option
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                viewModel.isIndoors = false
                            }
                        }) {
                            VStack(spacing: 12) {
                                Image(uiImage: .park)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 80)
                                    .scaleEffect(!viewModel.isIndoors ? 1.15 : 1.0)
                                    .accessibilityHidden(true)
                                
                                Text("Outdoors")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(!viewModel.isIndoors ? .primary : .secondary)
                                
                                Image(systemName: !viewModel.isIndoors ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(!viewModel.isIndoors ? Color.accentColor : Color.secondary)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Outdoors")
                        .accessibilityAddTraits(!viewModel.isIndoors ? [.isSelected] : [])
                        .accessibilityHint("Sets plant environment to outdoors")
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 16)
                } header: {
                    Text("Location")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                Section() {
                    Picker("Light Exposure", selection: $viewModel.lightExposure) {
                        ForEach(PlantLightExposure.allCases) {
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
        PageView(pageNumber: 5, pageTitle: "Your plant’s pot size?") {
            VStack(alignment: .leading, spacing: 14) {
                Section() {
                    Picker("Pot Size", selection: $viewModel.potSize) {
                        Text("(None)").tag(nil as PlantPotSize?)
                        ForEach(PlantPotSize.allCases) {
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
        PageView(pageNumber: viewModel.isLoading ? nil : 6, pageTitle: viewModel.isLoading ? "Analysing your plant..." : "Select your plant's garden",
                 shouldAddTitleMargin: viewModel.isLoading || gardenStore.gardens.isEmpty) {
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("This may take up to two minutes. Please be patient and keep the app open.")
                        .foregroundStyle(.secondary)
                }
            } else {
                if gardenStore.gardens.isEmpty {
                    VStack(spacing: 24) {
                        Image(uiImage: .carrot)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .clipped()
                            .accessibilityHidden(true)
                        
                        Text("You don't have any gardens yet. Create one to get started.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(alignment: .leading, spacing: 14) {
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
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(garden.name)
                            .accessibilityValue(garden.city)
                            .accessibilityAddTraits(viewModel.garden?.id == garden.id ? [.isSelected] : [])
                            .accessibilityHint("Selects \(garden.name)")
                            .buttonStyle(.plain)
                            
                            // Divider between rows
                            Divider()
                        }
                    }
                    
                    Button(action: { showAddGardenView = true }) {
                        Label("Create New", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel("Create New Garden")
                    .accessibilityHint("Opens screen to create a new garden")
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
        .sheet(isPresented: $showAddGardenView) {
            AddGardenView()
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }
}
