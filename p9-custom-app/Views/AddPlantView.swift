//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
import PhotosUI

enum FormStage: Int, CaseIterable {
    case photo = 0
    case species = 1
    case name = 2
    case location = 3
    case light = 4
    case age = 5
    case pot = 6
    case geoLocation = 7
}

struct AddPlantView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var currentStage: FormStage = .photo
    
    // Automatically focus text fields.
    @FocusState private var focusedField: FormStage?
    
    @State private var photoImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            // Progress bar.
            ProgressView(
                value: Double(currentStage.rawValue + 1),
                total: Double(FormStage.allCases.count)
            )
            .padding(.horizontal, 40)
            .padding(.top, 40)
            
            Spacer()
            
            ZStack {
                Group {
                    switch currentStage {
                    default:
                        QuestionView(number: 1, title: "Take a photo of your plant") {
                            VStack(spacing: 14) {
                                PhotosPicker(selection: $photoItem, matching: .images) {
                                    Label("Select Photo", systemImage: "photo.badge.plus")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .onChange(of: photoItem) { _, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            photoImage = uiImage
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
            
            HStack {
                if currentStage != .photo {
                    Button(action: previousStage) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.backward")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                if currentStage == .geoLocation {
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Text("Submit")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button(action: nextStage) {
                        HStack(spacing: 8) {
                            Text("Next").frame(maxWidth: .infinity)
                            Image(systemName: "arrow.forward")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
        }
        .navigationTitle("Add Plant")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .onChange(of: currentStage) { _, newValue in
            focusedField = newValue
        }
        .onAppear {
            focusedField = .photo
        }
    }
    
    private func nextStage() {
        if let next = FormStage(rawValue: currentStage.rawValue + 1) {
            currentStage = next
        }
    }
    
    private func previousStage() {
        if let prev = FormStage(rawValue: currentStage.rawValue - 1) {
            currentStage = prev
        }
    }
}

struct QuestionView<Content: View>: View {
    var number: Int
    var title: String
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ScrollView {
            VStack (spacing: 48) {
                HStack(alignment: .top, spacing: 8) {
                    Text("\(number).")
                        .font(.title.bold())
                    
                    Text(title)
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                content()
            }
            .padding(28)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .defaultScrollAnchor(.center, for: .alignment)
    }
}
