//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI

struct LogInView: View {
    
//    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 8) {
                    Text("Log In")
                        .font(.largeTitle.bold())
                    Text("Welcome back, fellow gardener.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 14) {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                        )
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                        )
                }
                .frame(maxWidth: 520)
                
                VStack(spacing: 14) {
                    Button(action: authenticate) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text("Log In").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                }
                .frame(maxWidth: 520)
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .appBackground()
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .alert("Authentication Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }
    
    private func authenticate() {
        
    }
}
