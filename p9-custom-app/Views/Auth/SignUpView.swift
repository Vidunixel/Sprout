//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Auth

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errors: [AppError] = []
    @State private var feedbackTrigger = false
    
    let emailRegex = #/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/#
    let passwordRegex = #/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$ %^&*-.]).{6,}$/#
    
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
                        Text("Full Name")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        let fullName = TextField("Enter your full name", text: $fullName)
                            .textContentType(.username)
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["full_name_empty"]
                        if let fullNameError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            fullName
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 2)
                                )
                            
                            Text("*\(fullNameError.localizedDescription)")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        } else {
                            fullName
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
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
                        
                        let passwordField = SecureField("Create a password", text: $password)
                            .textContentType(.password)
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["password_empty", "password_mismatch", "password_weak"]
                        if let passwordError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            passwordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 2)
                                )
                            
                            // Don't show error message if its a password_mismatch.
                            if !["password_mismatch"].contains(passwordError.errorCode) {
                                Text("*\(passwordError.localizedDescription)")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                                
                            }
                        } else {
                            passwordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirm Password")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        let confirmPasswordField = SecureField("Re-enter password", text: $confirmPassword)
                            .textContentType(.password)
                            .frame(height: 54)
                            .padding(.horizontal, 16)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(999)
                        
                        let targetErrors = ["confirm_password_empty", "password_mismatch"]
                        if let confirmPasswordError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                            confirmPasswordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemRed), lineWidth: 2)
                                )
                            
                            Text("*\(confirmPasswordError.localizedDescription)")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        } else {
                            confirmPasswordField
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
                
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
        .sensoryFeedback(.error, trigger: feedbackTrigger)
        .alert("Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            let alertError = errors.first(where: { $0.showAlert })
            Text(alertError?.localizedDescription ?? "An unknown error occurred.")
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { errors.removeAll { $0.showAlert } } }
        )
    }
    
    private func signUp() {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    try await authService.signUp(
                        fullName: fullName,
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
        validateFullName()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
    }
    
    private func validateFullName() {
        if fullName.isEmpty {
            errors.append(AppError("Full name is required.", "full_name_empty"))
        }
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
        } else if password.wholeMatch(of: passwordRegex) == nil {
            errors.append(
                AppError("""
                    Password must contain at least:
                    • 6 characters
                    • 1 upper case letter
                    • 1 lower case letter
                    • 1 number
                    • 1 special character.
                    """,
                    "password_weak"
                )
            )
        }
    }
    
    private func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            errors.append(AppError("Confirm password is required.", "confirm_password_empty"))
        } else if !password.isEmpty && password.wholeMatch(of: passwordRegex) != nil && password != confirmPassword {
            errors.append(AppError("Passwords do not match.", "password_mismatch"))
        }
    }
}
