//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI

struct LogInView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var viewModel = LogInViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 8) {
                    Text("Log In")
                        .font(.largeTitle.bold())
                    Text("Welcome back, fellow gardener.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 14) {
                    CustomField(
                        label: "Email",
                        errors: viewModel.errors,
                        targetErrorCodes: ["email_empty", "email_invalid", "invalid_credentials"],
                        silentErrorCodes: ["invalid_credentials"] // Don't show error message if its a invalid_credentials.
                    ) {
                        TextField("Enter your email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Email address")
                    }
                    
                    CustomField(
                        label: "Password",
                        errors: viewModel.errors,
                        targetErrorCodes: ["password_empty", "password_weak", "invalid_credentials"]
                    ) {
                        SecureField("Enter your password", text: $viewModel.password)
                            .textContentType(.password)
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Password")
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.logIn(authService: authService) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text("Log In").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityLabel("Log In")
                    .accessibilityValue(viewModel.isLoading ? "In progress" : "")
                    .accessibilityHint("Logs into your account")
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                    
                    NavigationLink(destination: ForgotPassword()) {
                        HStack {
                            Text("Forgot Password?")
                        }
                    }
                    .accessibilityHint("Opens screen to recover your password")
                    .font(.body)
                    .underline()
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .appBackground()
        .navigationTitle("Log In")
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
        .onChange(of: viewModel.dismissView) { _, newValue in
            if newValue {
                dismiss()
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
