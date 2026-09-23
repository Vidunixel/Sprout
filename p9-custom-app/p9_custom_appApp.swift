//
//  p9_custom_appApp.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]!)!,
    supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"]!
)

@main
struct p9_custom_appApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.green)
        }
    }
}
