//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Auth

struct SignUpView: View {
    
    @EnvironmentObject private var authService: AuthService
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errors: [AppError] = []
    @State private var feedbackTrigger = false
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 8) {
                    Text("Sign Up")
                        .font(.largeTitle.bold())
                    Text("Unlock smarter, simpler plant care.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        let usernameField = TextField("Username", text: $username)
                            .textContentType(.username)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["username_empty"]
                        if let usernameError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            usernameField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 3)
                                )
                            
                            Text("*\(usernameError.localizedDescription)")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        } else {
                            usernameField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        let emailField = TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["email_empty"]
                        if let emailError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            emailField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 3)
                                )
                            
                            Text("*\(emailError.localizedDescription)")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        } else {
                            emailField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        let passwordField = SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["password_empty", "password_mismatch"]
                        if let passwordError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            passwordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 3)
                                )
                            
                            Text("*\(passwordError.localizedDescription)")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        } else {
                            passwordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        let confirmPasswordField = SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.password)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["password_mismatch"]
                        if errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) != nil {
                            confirmPasswordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 3)
                                )
                        } else {
                            confirmPasswordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
                .frame(maxWidth: 520)
                
                VStack(spacing: 14) {
                    Button(action: signUp) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text("Create Account").frame(maxWidth: .infinity)
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
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .sensoryFeedback(.success, trigger: feedbackTrigger)
//        .alert("Authentication Error", isPresented: errorIsPresented) {
//            Button("OK", role: .cancel) { error = nil }
//        } message: {
//            Text(error?.localizedDescription ?? "Please try again.")
//        }
    }
    
//    private var errorIsPresented: Binding<Bool> {
//        Binding(get: { error != nil }, set: { if !$0 { error = nil } })
//    }
    
    private func signUp() {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    try await authService.signUp(
                        username: username,
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                } catch let error as AppError {
                    errors.append(error)
                }
            }
            
            if !errors.isEmpty {
                feedbackTrigger.toggle()
            }
        }
    }
    
    private func validateErrors() {
        errors = []
        validateUsername()
        validateEmail()
        validatePassword()
    }
    
    private func validateUsername() {
        if username.isEmpty {
            errors.append(AppError("Username is required.", "username_empty"))
        }
    }
    
    private func validateEmail() {
        if email.isEmpty {
            errors.append(AppError("Email is required.", "email_empty"))
        }
    }
    
    private func validatePassword() {
        if password.isEmpty {
            errors.append(AppError("Password is required.", "password_empty"))
        }
    }
}
