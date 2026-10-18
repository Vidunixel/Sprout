//
//  DetailedPlantView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 18/10/2026.
//

import SwiftUI

struct DetailedPlantView: View {
    @Environment(\.dismiss) private var dismiss
    
    let plant: Plant
    @State var gardenViewModel: GardenViewModel
    @State private var showPanel = true
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center) {
                if let scene = gardenViewModel.plantScenes[plant.id] {
                    PlantScene(scene: scene, allowHorizontalRotation: true, autoRotate: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 5)
                } else if gardenViewModel.plantLoadingStates[plant.id] == true {
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
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPanel) {
            DetailedPlantPanelView(executeDismissal: executeDismissal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct DetailedPlantPanelView: View {
    var executeDismissal: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Panel")
                    .font(.title)
            }
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
    }
}
