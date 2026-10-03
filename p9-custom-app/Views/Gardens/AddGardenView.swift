//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI

struct AddGardenView: View {
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        ScrollView {
            Button(action: { Task{ try? await authService.signOut() }}) {
                HStack {
                    Text("Log out").frame(maxWidth: .infinity)
                }
            }
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
    }
}
