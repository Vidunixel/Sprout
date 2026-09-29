//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Auth

struct UpdatePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errors: [AppError] = []
    @State private var feedbackTrigger = false
    
    let passwordRegex = #/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$ %^&*-.]).{6,}$/#
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                    
                    VStack(spacing: 8) {
                        Text("Update Password")
                            .font(.largeTitle.bold())
                    }
                }
                
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Password")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 2)
                        
                        let passwordField = SecureField("Create a new password", text: $password)
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
                        
                        let confirmPasswordField = SecureField("Re-enter new password", text: $confirmPassword)
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
                    Button(action: updatePassword) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text("Update").frame(maxWidth: .infinity)
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
        .sensoryFeedback(.success, trigger: feedbackTrigger)
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
    
    private func updatePassword() {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    try await authService.updatePassword(
                        newPassword: password
                    )
                    dismiss()
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
        validatePassword()
        validateConfirmPassword()
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
