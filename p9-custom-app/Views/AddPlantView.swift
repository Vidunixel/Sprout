//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
import PhotosUI

enum FormStage: Int, CaseIterable {
    case photo = 0
    case species = 1
    case name = 2
    case location = 3
    case light = 4
    case age = 5
    case pot = 6
    case geoLocation = 7
}

struct AddPlantView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var viewModel = AddPlantViewModel()
    
    @FocusState private var focusedField: FormStage? // Automatically focus text fields.
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
                    default:
                        Text("Test")
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
                
                if viewModel.currentStage == .geoLocation {
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            if viewModel.isLoading { ProgressView().tint(.white) }
                            Text("Submit")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                } else {
                    Button(action: viewModel.nextStage) {
                        HStack(spacing: 8) {
                            if viewModel.isLoading { ProgressView().tint(.white) }
                            Text("Next").frame(maxWidth: .infinity)
                            Image(systemName: "arrow.forward")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                }
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
        .onChange(of: viewModel.currentStage) { _, newValue in
            focusedField = newValue
        }
        .onAppear {
            focusedField = .photo
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
    
    private var currentPageTitle: String {
        switch viewModel.currentStage {
        case .photo:
            return "Upload a photo of your plant"
        case .species:
            return "Select plant species"
        default:
            return ""
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
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Select")
                        .font(.headline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
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
                        .padding(.bottom, 2)
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
