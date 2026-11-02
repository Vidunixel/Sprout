//
//  EditProfileView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 30/10/2026.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var viewModel: EditProfileViewModel
    
    init(currentName: String) {
        _viewModel = State(initialValue: EditProfileViewModel(currentName: currentName))
    }
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                VStack(spacing: 24) {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 8) {
                        Text("Personal Details")
                            .font(.largeTitle.bold())
                    }
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
                }
                
                VStack(spacing: 14) {
                    Button(action: { viewModel.updateProfile(authService: authService) }) {
                        HStack {
                            if viewModel.isLoading { ProgressView().tint(.white).accessibilityHidden(true) }
                            Text("Save").frame(maxWidth: .infinity)
                        }
                    }
                    .accessibilityLabel("Save")
                    .accessibilityValue(viewModel.isLoading ? "In progress" : "")
                    .accessibilityHint("Saves your updated name")
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
        .navigationTitle("Personal Details")
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
