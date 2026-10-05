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
class VerifyEmailViewModel {
    var email = ""
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var timeRemaining = 30
    let passwordRegex = #/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$ %^&*-.]).{6,}$/#
    
    init(email: String) {
        self.email = email
    }
    
    func resendVerificationEmail(authService: AuthService) {
        isLoading = true
        Task {
            defer { isLoading = false }
            if (errors.isEmpty) {
                do {
                    try await authService.resendVerificationEmail(email: email)
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
}
