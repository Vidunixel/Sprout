//
//  VerifyEmail.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
internal import Combine

struct ForgotPassword: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var viewModel = ForgotPasswordViewModel()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "lock.badge.clock.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 8) {
                        Text("Forgot Password")
                            .font(.largeTitle.bold())
                        
                        if viewModel.hasSentEmail {
                            Text("We sent a password reset link to **\(viewModel.email)**.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Send a password reset link to your email address.")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                CustomField(
                    label: "Email",
                    errors: viewModel.errors,
                    targetErrorCodes: ["email_empty", "email_invalid"]
                ) {
                    TextField("Enter your email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 6)
                        .accessibilityLabel("Email address")
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.sendPasswordResetEmail(authService: authService) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text(viewModel.hasSentEmail ? "Resend Email" : "Send Reset Link")
                                .frame(maxWidth: .infinity)
                            
                            if (viewModel.timeRemaining > 0) {
                                Text(String(viewModel.timeRemaining))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .accessibilityLabel(viewModel.hasSentEmail ? "Resend Reset Link" : "Send Reset Link")
                    .accessibilityValue(viewModel.timeRemaining > 0 ? "\(viewModel.timeRemaining) seconds remaining" : (viewModel.isLoading ? "In progress" : ""))
                    .accessibilityHint("Sends password reset instructions to your email")
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(viewModel.timeRemaining > 0 || viewModel.isLoading)
                    
                    Button(action: {dismiss()}) {
                        HStack {
                            Text("Back to Log In").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityHint("Dismisses this screen and returns to log in")
                    .buttonStyle(.glass)
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
        .sensoryFeedback(.error, trigger: viewModel.feedbackTrigger)
        .alert("Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            let alertError = viewModel.errors.first(where: { $0.showAlert })
            Text(alertError?.localizedDescription ?? "An unknown error occurred.")
        }
        .onReceive(timer) { _ in
            if viewModel.timeRemaining > 0 {
                viewModel.timeRemaining -= 1
            }
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { viewModel.errors.removeAll { $0.showAlert } } }
        )
    }
}
