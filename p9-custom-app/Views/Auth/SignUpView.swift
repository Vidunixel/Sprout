//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Auth

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var viewModel = SignUpViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 8) {
                    Text("Sign Up")
                        .font(.largeTitle.bold())
                    Text("Unlock smarter, simpler plant care.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 14) {
                    CustomField(
                        label: "Full Name",
                        errors: viewModel.errors,
                        targetErrorCodes: ["full_name_empty"]
                    ) {
                        TextField("Enter your full name", text: $viewModel.fullName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Full name")
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
                    
                    CustomField(
                        label: "Password",
                        errors: viewModel.errors,
                        targetErrorCodes: ["password_empty", "password_mismatch", "password_weak"],
                        silentErrorCodes: ["password_mismatch"]
                    ) {
                        SecureField("Create a password", text: $viewModel.password)
                            .textContentType(.password)
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Password")
                    }
                    
                    CustomField(
                        label: "Confirm Password",
                        errors: viewModel.errors,
                        targetErrorCodes: ["confirm_password_empty", "password_mismatch"]
                    ) {
                        SecureField("Re-enter password", text: $viewModel.confirmPassword)
                            .textContentType(.password)
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Confirm password")
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.signUp(authService: authService) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text("Create Account").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityLabel("Create Account")
                    .accessibilityValue(viewModel.isLoading ? "In progress" : "")
                    .accessibilityHint("Submits registration form to create an account")
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .appBackground()
        .navigationTitle("Sign Up")
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
