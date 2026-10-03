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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        let nameField = TextField("Enter a name", text: $viewModel.name)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("City")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        HStack(spacing: 4) {
                            VStack(alignment: .leading, spacing: 4) {
                                let cityField = TextField("Enter a city", text: $viewModel.city)
                                    .focused($isCityFocused)
                                    .onChange(of: viewModel.city) { _, newValue in
                                        if isCityFocused {
                                            viewModel.cityCompleter.search(query: newValue)
                                        }
                                    }
                                    .textContentType(.addressCity)
                                    .autocorrectionDisabled()
                                    .frame(height: 54)
                                    .padding(.horizontal, 16)
                                    .background(Color(uiColor: .systemBackground))
                                    .cornerRadius(999)
                                
                                let targetErrors = ["city_empty"]
                                if let cityError = viewModel.errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                                    cityField
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999)
                                                .stroke(Color(uiColor: .systemRed), lineWidth: 2)
                                        )
                                    
                                    Text("*\(cityError.localizedDescription)")
                                        .font(.caption.bold())
                                        .foregroundColor(.red)
                                } else {
                                    cityField
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999)
                                                .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                        )
                                }
                            }
                            
                            Button(action: {}) {
                                Label("Current Location", systemImage: "location")
                            }
                            .buttonBorderShape(.circle)
                            .controlSize(.large)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isLoading)
                        }
                        
                        if !viewModel.cityResults.isEmpty {
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
                                    
                                    // Divider between rows
                                    if result != viewModel.cityResults.last {
                                        Divider().padding(.horizontal, 16)
                                    }
                                }
                            }
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
                    Button(action: {}) {
                        HStack {
                            Text("Create").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
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
            setupAutocomplete()
        }
    }
    
    private func setupAutocomplete() {
        viewModel.cityCompleter.onResultsUpdated = { results in
            viewModel.cityResults = results
        }
        
        viewModel.cityCompleter.onError = { error in
            print("Autocomplete error: \(error.localizedDescription)")
        }
    }
    
    private func handleAutocompleteSelection(result: MKLocalSearchCompletion) {
        isCityFocused = false
        viewModel.cityCompleter.cancel()
        viewModel.cityResults = []
        
        // Let SwiftUI finish unfocusing before updating
        DispatchQueue.main.async {
            viewModel.city = result.title
        }
    }
}
