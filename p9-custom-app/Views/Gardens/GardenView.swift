//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
import Supabase

struct GardenView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var gardenStore: GardenStore
    
    @State private var viewModel = GardenViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                if gardenStore.gardens.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "carrot")
                            .font(.system(size: 100))
                            .foregroundStyle(.tint)
                        
                        Text("You don't have any gardens yet. Create one to get started.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    if gardenStore.gardens.isEmpty {
                        Button(action: { viewModel.showAddGardenView = true }) {
                            Label("Create New", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
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
