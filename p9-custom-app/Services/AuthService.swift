import Foundation
import Observation
import Supabase
internal import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var awaitingVerificationEmail: String? = nil
    
    init() {
        Task {
            for await (_, session) in supabase.auth.authStateChanges {
                self.session = session
            }
        }
    }
    
    func signUp(fullName: String, email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(fullName)]
            )
            
            print(response)
            
            if response.user.emailConfirmedAt == nil {
                self.awaitingVerificationEmail = email
            }
        } catch let error as AuthError {
            print(error)
            throw AppError(error.localizedDescription, error.errorCode.rawValue, showAlert: true)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            
            if response.user.emailConfirmedAt == nil {
                self.awaitingVerificationEmail = email
            }
        } catch let error as AuthError {
            var description: String
            var showAlert: Bool
            
            // Customise errors.
            switch error.errorCode.rawValue {
            case "invalid_credentials":
                showAlert = false
                description = "Email or password is incorrect."
            default:
                showAlert = true
                description = error.localizedDescription
            }
            
            throw AppError(description, error.errorCode.rawValue, showAlert: showAlert)
        }
    }
    
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue, showAlert: true)
        }
    }
    
    func sendPasswordResetEmail(email: String) async throws {
        let edgeFunctionURL = URL(string: "https://ucjxcrmfkkujjdgtbjuz.supabase.co/functions/v1/auth?action=reset-password")!
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                redirectTo: edgeFunctionURL
            )
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue, showAlert: true)
        }
    }
    
    func resendVerificationEmail(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resend(email: email, type: .signup)
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue, showAlert: true)
        }
    }
    
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue, showAlert: true)
        }
    }
}
