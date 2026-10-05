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
class LogInViewModel {
    var dismissView = false
    var email = ""
    var password = ""
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    let emailRegex = #/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/#
    
    func logIn(authService: AuthService) {
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
                        dismissView = true
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
