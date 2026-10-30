//
//  Chip.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import SwiftUI

struct CustomField<Content: View>: View {
    let label: String?
    var errors: [AppError] = []
    var targetErrorCodes: [String] = []
    var silentErrorCodes: [String] = [] // Errors which only show red border (no description).
    
    @ViewBuilder var content: () -> Content
    
    init(
        label: String? = nil,
        errors: [AppError] = [],
        targetErrorCodes: [String] = [],
        silentErrorCodes: [String] = [],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.errors = errors
        self.targetErrorCodes = targetErrorCodes
        self.silentErrorCodes = silentErrorCodes
        self.content = content
    }
    
    // If this specific field has an error.
    private var activeError: AppError? {
        errors.first(where: { targetErrorCodes.contains($0.errorCode ?? "") })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
            }
            
            VStack(alignment: .leading) {
                content()
            }
            .frame(minHeight: 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                // Toggle border colour and width based on activeError.
                    .stroke(
                        activeError != nil ? Color(uiColor: .systemRed) : Color.primary.opacity(0.05),
                        lineWidth: activeError != nil ? 2 : 1
                    )
            )
            
            // Conditionally show the error text
            if let error = activeError, let errorCode = error.errorCode, !silentErrorCodes.contains(errorCode) {
                Text("*\(error.localizedDescription)")
                    .font(.caption.bold())
                    .foregroundColor(.red)
            }
        }
    }
}
