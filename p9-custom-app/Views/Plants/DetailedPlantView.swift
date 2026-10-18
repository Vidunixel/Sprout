//
//  DetailedPlantView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 18/10/2026.
//

import SwiftUI

import SwiftUI

struct DetailedPlantView: View {
    let plant: Plant
    @State var gardenViewModel: GardenViewModel
    
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
        .onAppear {
            gardenViewModel.showDetailedPlantPanelView = true
        }
        .onDisappear {
            gardenViewModel.showDetailedPlantPanelView = false
        }
        .appBackground()
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailedPlantPanelView: View {
    var body: some View {
        VStack {
            Text("Panel")
                .font(.title)
        }
    }
}
