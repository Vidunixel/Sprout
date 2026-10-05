//
//  ForgotPasswordViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 5/10/2026.
//

import SwiftUI
import Observation

@Observable
@MainActor
class UpdatePasswordViewModel {
    var dismissView = false
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    let passwordRegex = #/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$ %^&*-.]).{6,}$/#
    
    func updatePassword(authService: AuthService) {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    try await authService.updatePassword(
                        newPassword: password
                    )
                    dismissView = true
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
