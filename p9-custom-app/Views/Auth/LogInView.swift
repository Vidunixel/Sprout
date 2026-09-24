//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI

struct LogInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errors: [AppError] = []
    @State private var feedbackTrigger = false
    
    let emailRegex = #/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/#
    let passwordRegex = #/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$ %^&*-.]).{8,}$/#
    
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        let emailField = TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["email_empty", "email_invalid"]
                        if let emailError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            emailField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 2)
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
                        Text("Password")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        let passwordField = SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["password_empty", "password_weak"]
                        if let passwordError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            passwordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 2)
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
                }
                
                VStack(spacing: 14) {
                    Button(action: logIn) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text("Log In").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                }
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
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        .alert("Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            let alertError = errors.first(where: { $0.showAlert })
            Text(alertError?.localizedDescription ?? "An unknown error occured.")
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { errors.removeAll { $0.showAlert } } }
        )
    }
    
    private func logIn() {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    try await authService.signIn(
                        email: email,
                        password: password
                    )
                    
                    // Dismiss if email not verified
                    if (authService.awaitingVerificationEmail != nil) {
                        dismiss()
                    }
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
        validateEmail()
        validatePassword()
    }
    
    private func validateEmail() {
        if email.isEmpty {
            errors.append(AppError("Email is required.", "email_empty"))
        }  else if email.wholeMatch(of: emailRegex) == nil {
            errors.append(AppError("Invalid email address.", "email_invalid"))
        }
    }
    
    private func validatePassword() {
        if password.isEmpty {
            errors.append(AppError("Password is required.", "password_empty"))
        }
    }
}
