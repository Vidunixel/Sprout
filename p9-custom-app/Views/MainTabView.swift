//
//  MainTabView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 29/9/2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TasksView()
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }
            
            NavigationStack {
                GardenView()
            }
            .tabItem { Label("Garden", systemImage: "carrot") }
            
            NavigationStack {
                GardenView()
            }
            .tabItem { Label("History", systemImage: "clock") }
            
            NavigationStack {
                GardenView()
            }
            .tabItem { Label("Account", systemImage: "person") }
        }
    }
}
