//
//  AccountViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 29/10/2026.
//

import SwiftUI
import Observation

@Observable @MainActor
class AccountViewModel {
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var isTaskRemindersEnabled = true
    
    func signOut(authService: AuthService) {
        isLoading = true
        Task {
            defer { isLoading = false }
            errors = []
            
            do {
                try await authService.signOut()
            } catch let error as AppError {
                errors.append(error)
            } catch {
                errors.append(AppError(error.localizedDescription, showAlert: true))
            }
            
            if !errors.isEmpty {
                feedbackTrigger.toggle()
            }
        }
    }
}
