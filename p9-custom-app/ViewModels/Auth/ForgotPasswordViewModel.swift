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
class ForgotPasswordViewModel {
    var email = ""
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var timeRemaining = 0
    var hasSentEmail = false
    let emailRegex = #/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/#
    
    func sendPasswordResetEmail(authService: AuthService) {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    try await authService.sendPasswordResetEmail(email: email)
                    hasSentEmail = true
                    timeRemaining = 30
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
    }
    
    private func validateEmail() {
        if email.isEmpty {
            errors.append(AppError("Email is required.", "email_empty"))
        }  else if email.wholeMatch(of: emailRegex) == nil {
            errors.append(AppError("Invalid email address.", "email_invalid"))
        }
    }
}
