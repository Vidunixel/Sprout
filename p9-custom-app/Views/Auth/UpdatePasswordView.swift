//
//  AuthenticationView.swift
//  p5-lab6
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI
import Auth

struct UpdatePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var viewModel = UpdatePasswordViewModel()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 8) {
                        Text("Update Password")
                            .font(.largeTitle.bold())
                    }
                }
                
                VStack(spacing: 14) {
                    CustomField(
                        label: "New Password",
                        errors: viewModel.errors,
                        targetErrorCodes: ["password_empty", "password_mismatch", "password_weak"],
                        silentErrorCodes: ["password_mismatch"]
                    ) {
                        SecureField("Create a new password", text: $viewModel.password)
                            .textContentType(.password)
                            .padding(.horizontal, 6)
                            .accessibilityLabel("New password")
                    }
                    
                    CustomField(
                        label: "Confirm Password",
                        errors: viewModel.errors,
                        targetErrorCodes: ["confirm_password_empty", "password_mismatch"]
                    ) {
                        SecureField("Re-enter new password", text: $viewModel.confirmPassword)
                            .textContentType(.password)
                            .padding(.horizontal, 6)
                            .accessibilityLabel("Confirm new password")
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.updatePassword(authService: authService) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text("Update").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityLabel("Update Password")
                    .accessibilityValue(viewModel.isLoading ? "In progress" : "")
                    .accessibilityHint("Submits your new password")
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
        .interactiveDismissDisabled(viewModel.isLoading)
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { viewModel.errors.removeAll { $0.showAlert } } }
        )
    }
}
