//
//  Chip.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import SwiftUI

struct CustomField<Content: View>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var isSecure: Bool = false
    var errors: [AppError] = []
    var targetErrorCodes: [String] = []
    var silentErrorCodes: [String] = [] // Errors which only show red border (no description).
    
    var hiddenField: Bool = false
    var disabledField: Bool = false
    
    @ViewBuilder var content: () -> Content
    
    // If this specific field has an error.
    private var activeError: AppError? {
        errors.first(where: { targetErrorCodes.contains($0.errorCode ?? "") })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            
            VStack (alignment: .leading) {
                content()
                
                if !hiddenField {
                    Group {
                        if isSecure {
                            SecureField(placeholder, text: $text)
                        } else {
                            TextField(placeholder, text: $text)
                        }
                    }
                    .disabled(disabledField)
                }
            }
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                // Toggle border colour and width based on activeError.
                    .stroke(
                        activeError != nil ? Color(uiColor: .systemRed) : Color(uiColor: .systemGray4),
                        lineWidth: activeError != nil ? 2 : 1
                    )
            )
            
            // Conditionally show the error text
            if let error = activeError, let errorCode = error.errorCode, !silentErrorCodes.contains(errorCode) {
                Text("*\(error.localizedDescription)")
                    .font(.caption.bold())
                    .foregroundColor(.red)
                    .padding(.leading, 16)
            }
        }
    }
}
