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
                GardenView()
            }
            .tabItem { Label("Garden", systemImage: "carrot") }
            
            NavigationStack {
                TasksView()
            }
            .tabItem { Label("Tasks", systemImage: "checklist") }
            
            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock") }
            
            NavigationStack {
                AccountView()
            }
            .tabItem { Label("Account", systemImage: "person") }
        }
    }
}
