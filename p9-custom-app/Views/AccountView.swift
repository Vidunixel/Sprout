//
//  TasksView.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 24/9/2026.
//

import SwiftUI
import Supabase

struct AccountView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var plantStore: PlantStore
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var gardenStore: GardenStore
    
    @State private var viewModel = AccountViewModel()
    
    var userEmail: String {
        authService.session?.user.email ?? "Unknown"
    }
    
    var displayName: String {
        if let name = authService.session?.user.userMetadata["display_name"] {
            return "\(name)".replacingOccurrences(of: "\"", with: "")
        }
        return "Gardener"
    }
    
    var diceBearURL: URL? {
        let seed = userEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.dicebear.com/10.x/sprouts/png?mouthVariant=smile,tinySmile,ooh,line,catMouth,frown,wavy,tooth&backgroundColor=3a3a3f,41413a,3a4140,3f3a41&potColor=a5a58d,b98b73,8e9aaf,9c8a94,b0a58c,94a3ad&plantColor=7c9082,6b7a5e,8a9c7a,5f7263&seed=\(seed)"
        return URL(string: urlString)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    AsyncImage(url: diceBearURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .empty:
                            ProgressView()
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 75, height: 75)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.title3.bold())
                            
                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        HStack(spacing: 8) {
                            Text("\(plantStore.plants.count) \(plantStore.plants.count == 1 ? "plant" : "plants")")
                                .brightness(-0.1)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            Section {
                NavigationLink(destination: Text("Personal details coming soon...")) {
                    Label {
                        Text("Personal details")
                    } icon: {
                        Image(systemName: "person.fill")
                    }
                }
            } header: {
                Text("Profile")
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            Section {
                Toggle(isOn: $viewModel.isTaskRemindersEnabled) {
                    Label {
                        Text("Task reminders")
                    } icon: {
                        Image(systemName: "bell.fill")
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Notify me of tasks on their due dates.")
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            Section {
                NavigationLink(destination: UpdatePasswordView()) {
                    Label {
                        Text("Change password")
                    } icon: {
                        Image(systemName: "lock.fill")
                    }
                }
            } header: {
                Text("Security")
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            Section {
                Button(action: { viewModel.signOut(authService: authService) }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("Sign out")
                            .foregroundStyle(.red)
                    }
                }
                .disabled(viewModel.isLoading)
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            Section {
                HStack {
                    Spacer()
                    Text("Sprout v1 · Made with ❤️ by Vidun Herath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
        .scrollContentBackground(.hidden)
        .appBackground()
        .onChange(of: viewModel.isTaskRemindersEnabled) { _, newValue in
            if newValue {
                NotificationService.shared.syncNotifications(
                    tasks: taskStore.tasks,
                    plants: plantStore.plants,
                    gardens: gardenStore.gardens
                )
            } else {
                NotificationService.shared.clearAllNotifications()
            }
        }
        .sensoryFeedback(.error, trigger: viewModel.feedbackTrigger)
        .alert("Error", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            let alertError = viewModel.errors.first(where: { $0.showAlert })
            Text(alertError?.localizedDescription ?? "An unknown error occurred.")
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errors.contains(where: { $0.showAlert }) },
            set: { if !$0 { viewModel.errors.removeAll { $0.showAlert } } }
        )
    }
}
