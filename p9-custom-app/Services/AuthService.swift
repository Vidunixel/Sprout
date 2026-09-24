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
            throw AppError(error.localizedDescription, error.errorCode.rawValue, showAlert: true)
        }
    }
    
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
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
}
