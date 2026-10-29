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
    
    var isTaskRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTaskRemindersEnabled, forKey: "isTaskRemindersEnabled")
            
            if isTaskRemindersEnabled {
                // If permission denied, set isTaskRemindersEnabled to false
                NotificationService.shared.requestPermission { granted in
                    if !granted {
                        Task { @MainActor in
                            self.isTaskRemindersEnabled = false
                        }
                    }
                }
            } else {
                // Clear notifications.
                NotificationService.shared.clearAllNotifications()
            }
        }
    }
    
    init() {
        let savedState = UserDefaults.standard.object(forKey: "isTaskRemindersEnabled") != nil
            ? UserDefaults.standard.bool(forKey: "isTaskRemindersEnabled")
            : true
        
        self.isTaskRemindersEnabled = savedState
        
        if savedState {
            // If permission denied, set isTaskRemindersEnabled to false
            NotificationService.shared.checkAuthorizationStatus { isAuthorized in
                if !isAuthorized && UserDefaults.standard.object(forKey: "isTaskRemindersEnabled") != nil {
                    self.isTaskRemindersEnabled = false
                }
            }
        }
    }
    
    func signOut(authService: AuthService) {
        isLoading = true
        Task {
            defer { isLoading = false }
            errors = []
            
            do {
                // Wipe notifications before signing out.
                NotificationService.shared.clearAllNotifications()
                
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
