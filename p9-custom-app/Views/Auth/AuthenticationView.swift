//
//  AuthenticationView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            if let email = authService.awaitingVerificationEmail {
                VerifyEmail(email: email)
            } else {
                ScrollView {
                    VStack (spacing: 48) {
                        VStack(spacing: 24) {
                            if let appIcon = UIImage(named: "AppIconImage") {
                                Image(uiImage: appIcon)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Sprout")
                                    .font(.largeTitle.bold())
                                Text("Plant care made simple. Let it sprout.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        VStack(spacing: 14) {
                            NavigationLink(destination: LogInView()) {
                                HStack {
                                    Text("Log In").frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                            
                            NavigationLink(destination: SignUpView()) {
                                HStack {
                                    Text("Create an Account").frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.glass)
                            .controlSize(.large)
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                }
                .navigationTitle("Welcome")
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
    }
}
