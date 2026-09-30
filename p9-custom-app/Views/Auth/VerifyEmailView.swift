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
    @State var email: String
    @State private var isLoading = false
    @State private var errors: [AppError] = []
    @State private var feedbackTrigger = false
    
    @State private var timeRemaining = 30
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                    
                    VStack(spacing: 8) {
                        Text("Verify Email")
                            .font(.largeTitle.bold())
                        Text("We sent a verification link to **\(email)**.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 14) {
                    Button(action: resendVerificationEmail) {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text("Resend Email").frame(maxWidth: .infinity)
                            
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
                    .disabled(timeRemaining > 0)
                    
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
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .sensoryFeedback(.error, trigger: feedbackTrigger)
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
    
    private func resendVerificationEmail() {
        isLoading = true
        Task {
            defer { isLoading = false }
            if (errors.isEmpty) {
                do {
                    try await authService.resendVerificationEmail(email: email)
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
}
