//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI

struct GardenView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var showAddPlantView = false
    
    var body: some View {
        ScrollView {
            Button(action: { Task{ try? await authService.signOut() }}) {
                HStack {
                    Text("Log out").frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showAddPlantView) {
            AddPlantView()
        }
        .navigationTitle("Garden")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddPlantView.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .appBackground()
    }
}
