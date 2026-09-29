//
//  VerifyEmail.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
internal import Combine

struct ForgotPassword: View {
    @EnvironmentObject var authService: AuthService
    @State var email = ""
    @State private var isLoading = false
    @State private var errors: [AppError] = []
    @State private var feedbackTrigger = false
    
    @State private var timeRemaining = 0
    @State private var hasSentEmail = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let emailRegex = #/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/#
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "lock.badge.clock.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                    
                    VStack(spacing: 8) {
                        Text("Forgot Password")
                            .font(.largeTitle.bold())
                        
                        if hasSentEmail {
                            Text("We sent a password reset link to **\(email)**.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Send a password reset link to your email address.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    
                    let emailField = TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(height: 54)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(999)
                    
                    let targetErrors = ["email_empty", "email_invalid"]
                    if let emailError = errors.first(where: { targetErrors.contains($0.errorCode ?? "") }) {
                        emailField
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color(uiColor: .systemRed), lineWidth: 2)
                            )
                        
                        Text("*\(emailError.localizedDescription)")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    } else {
                        emailField
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                            )
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: sendPasswordResetEmail) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(hasSentEmail ? "Resend Email" : "Send Reset Link")
                                .frame(maxWidth: .infinity)
                            
                            if (timeRemaining > 0) {
                                Text(String(timeRemaining))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(timeRemaining > 0 || isLoading)
                    
                    Button(action: {
                        authService.awaitingVerificationEmail = nil
                        Task { try? await authService.signOut()}
                    }) {
                        HStack {
                            Text("Back to Log In").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .appBackground()
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .sensoryFeedback(.success, trigger: feedbackTrigger)
        .alert("Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            let alertError = errors.first(where: { $0.showAlert })
            Text(alertError?.localizedDescription ?? "An unknown error occurred.")
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { errors.removeAll { $0.showAlert } } }
        )
    }
    
    private func sendPasswordResetEmail() {
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
