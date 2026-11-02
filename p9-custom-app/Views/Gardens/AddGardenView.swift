//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
internal import MapKit

struct AddGardenView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var gardenStore: GardenStore
    
    @State private var viewModel = AddGardenViewModel()
    @FocusState private var isCityFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Create Garden")
                            .font(.largeTitle.bold())
                        
                        Text("Create a space to organise your plants.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 14) {
                    CustomField(
                        label: "Name",
                        errors: viewModel.errors,
                        targetErrorCodes: ["name_empty"]
                    ) {
                        TextField("Enter a name", text: $viewModel.name)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Garden name")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            CustomField(
                                label: "City",
                                errors: viewModel.errors,
                                targetErrorCodes: ["city_empty"]
                            ) {
                                if viewModel.city != nil {
                                    Chip(title: viewModel.city ?? "Unknown") {
                                        viewModel.city = nil
                                    }
                                }
                                
                                HStack {
                                    TextField("Enter a city", text: $viewModel.citySearch)
                                        .focused($isCityFocused)
                                        .onChange(of: viewModel.citySearch) { _, newValue in
                                            if isCityFocused {
                                                viewModel.cityCompleter.search(query: newValue)
                                            }
                                        }
                                        .textContentType(.addressCity)
                                        .autocorrectionDisabled()
                                        .padding(.horizontal, 6)
                                        .accessibilityLabel("City")
                                    
                                    Button(action: { viewModel.setCurrentCity() }) {
                                        Label("Current Location", systemImage: "location")
                                    }
                                    .accessibilityLabel("Current location")
                                    .accessibilityHint("Uses device GPS to detect and set current city")
                                    .buttonBorderShape(.circle)
                                    .controlSize(.regular)
                                    .labelStyle(.iconOnly)
                                    .buttonStyle(.bordered)
                                    .disabled(viewModel.isLoading)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        
                        if !viewModel.cityResults.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.cityResults, id: \.self) { result in
                                        Button(action: { handleAutocompleteSelection(result: result) }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(result.title)
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                        }
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel(result.title)
                                        .accessibilityValue(result.subtitle.isEmpty ? "" : result.subtitle)
                                        .accessibilityHint("Selects this city")
                                        
                                        // Divider between rows
                                        if result != viewModel.cityResults.last {
                                            Divider().padding(.horizontal, 16)
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 240)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(uiColor: .systemGray5), lineWidth: 1)
                            )
                            .padding(.top, 4)
                        }
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.createGarden(authService: authService, gardenStore: gardenStore) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text("Create").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityLabel("Create Garden")
                    .accessibilityValue(viewModel.isLoading ? "In progress" : "")
                    .accessibilityHint("Creates the garden with the specified details")
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("Add Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .appBackground()
        .onAppear {
            viewModel.setupAutocomplete()
        }
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
        .interactiveDismissDisabled(viewModel.isLoading)
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { viewModel.errors.removeAll { $0.showAlert } } }
        )
    }
    
    func handleAutocompleteSelection(result: MKLocalSearchCompletion) {
        isCityFocused = false
        viewModel.handleAutocompleteSelection(result: result)
    }
}
