//
//  EditProfileViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 30/10/2026.
//

import SwiftUI
import Observation

@Observable @MainActor class EditProfileViewModel {
    var dismissView = false
    var fullName = ""
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    init(currentName: String) {
        self.fullName = currentName
    }
    
    func updateProfile(authService: AuthService) {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            
            if errors.isEmpty {
                do {
                    try await authService.updateFullName(newName: fullName)
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
        validateFullName()
    }
    
    private func validateFullName() {
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(AppError("Full name is required.", "full_name_empty"))
        }
    }
}
