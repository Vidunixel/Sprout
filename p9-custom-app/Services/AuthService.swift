import Foundation
import Observation
import Supabase
internal import Combine

@MainActor
final class AuthService: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        Task {
            for await (_, session) in supabase.auth.authStateChanges {
                self.session = session
            }
        }
    }
    
    func signUp(username: String, email: String, password: String, confirmPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _ = try await supabase.auth.signUp(email: email, password: password)
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let _ = try await supabase.auth.signIn(email: email, password: password)
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue)
        }
    }
    
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
        } catch let error as AuthError {
            throw AppError(error.localizedDescription, error.errorCode.rawValue)
        }
    }
}
