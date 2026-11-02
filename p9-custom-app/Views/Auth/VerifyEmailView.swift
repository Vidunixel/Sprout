//
//  VerifyEmail.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
internal import Combine

struct VerifyEmail: View {
    @EnvironmentObject var authService: AuthService
    @State private var viewModel: VerifyEmailViewModel
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(email: String) {
        // Pass the email to the viewModel
        _viewModel = State(initialValue: VerifyEmailViewModel(email: email))
    }
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 8) {
                        Text("Verify Email")
                            .font(.largeTitle.bold())
                        Text("We sent a verification link to **\(viewModel.email)**.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.resendVerificationEmail(authService: authService) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text("Resend Email").frame(maxWidth: .infinity)
                            
                            if (viewModel.timeRemaining > 0) {
                                Text(String(viewModel.timeRemaining))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 2)
                            }
                        }
                    }
                    .accessibilityLabel("Resend Email")
                    .accessibilityValue(viewModel.timeRemaining > 0 ? "\(viewModel.timeRemaining) seconds remaining" : (viewModel.isLoading ? "In progress" : ""))
                    .accessibilityHint("Resends verification email to your email address")
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(viewModel.timeRemaining > 0)
                    
                    Button(action: {
                        authService.awaitingVerificationEmail = nil
                        Task { try? await authService.signOut()}
                    }) {
                        HStack {
                            Text("Back to Log In").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityHint("Returns to the log in screen")
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .appBackground()
        .navigationTitle("Verify Email")
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
