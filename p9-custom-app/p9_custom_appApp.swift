//
//  p9_custom_appApp.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Supabase

let supabase = SupabaseClient(
    supabaseURL: AppConfig.supabaseURL,
    supabaseKey: AppConfig.supabasePublishableKey
)

@main
struct p9_custom_appApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.green)
                .environmentObject(authService)
        }
    }
}
