//
//  ContentView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        Group {
            AuthenticationView()
        }
        .environmentObject(authService)
    }
}
