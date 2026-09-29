//
//  ContentView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Supabase

struct RootView: View {
    @StateObject private var authService = AuthService()
    @State private var showResetPasswordView = false
    
    var body: some View {
        Group {
            if (authService.session != nil) {
                TasksView()
            } else {
                AuthenticationView()
            }
        }
        .environmentObject(authService)
        .sheet(isPresented: $showResetPasswordView) {
            ResetPasswordView()
        }
        .onOpenURL { url in
            // Catch deeplink for supabase auth redirect.
            if (url.host == "auth") {
                Task {
                    do {
                        // Log user in
                        try await supabase.auth.session(from: url)
                        
                        if url.path == "/reset-password" {
                            showResetPasswordView = true
                        }
                    } catch {
                        print("Auth error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
