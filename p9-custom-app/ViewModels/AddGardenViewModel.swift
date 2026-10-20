//
//  AddGardenViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import SwiftUI
import Observation
import Supabase
internal import MapKit

@Observable
@MainActor
class AddGardenViewModel {
    var dismissView = false
    
    var name = ""
    var city: String?
    var geoLocation: [Double]?
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var citySearch = ""
    var cityCompleter = LocalityAutocomplete()
    var cityResults: [MKLocalSearchCompletion] = []
    
    private let manager = CLLocationManager()
    
    func setCurrentCity() {
        Task {
            do {
                // Ask for permission.
                if manager.authorizationStatus == .notDetermined {
                    manager.requestWhenInUseAuthorization()
                }
                
                guard manager.authorizationStatus != .denied && manager.authorizationStatus != .restricted else {
                    throw AppError("Location access denied. Please enable in Settings.", showAlert: true)
                }
                
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if let location = update.location {
                        self.geoLocation = [location.coordinate.latitude, location.coordinate.longitude]
                                                
                        // Reverse geocode to get city.
                        if let request = MKReverseGeocodingRequest(location: location) {
                            if let mapitems = try? await request.mapItems, let addressRepresentations = mapitems.first?.addressRepresentations {
                                self.city = addressRepresentations.cityName
                            }
                        }
                        
                        // Get location once.
                        break
                    }
                }
            } catch let error as AppError {
                errors.append(error)
                self.feedbackTrigger.toggle()
            }
        }
    }
    
    func setupAutocomplete() {
        cityCompleter.onResultsUpdated = { results in
            self.cityResults = results
        }
        
        cityCompleter.onError = { error in
            print("Autocomplete error: \(error.localizedDescription)")
        }
    }
    
    func handleAutocompleteSelection(result: MKLocalSearchCompletion) {
        citySearch = ""
        cityCompleter.cancel()
        cityResults = []
        
        Task {
            let searchRequest = MKLocalSearch.Request(completion: result)
            let search = MKLocalSearch(request: searchRequest)
            
            do {
                let response = try await search.start()
                if let mapItem = response.mapItems.first {
                    // Save geolocation.
                    self.geoLocation = [mapItem.location.coordinate.latitude, mapItem.location.coordinate.longitude]
                    
                    // Save city.
                    self.city = mapItem.addressRepresentations?.cityName
                }
            } catch {
                self.errors.append(AppError("Failed to fetch location details.", showAlert: true))
                self.feedbackTrigger.toggle()
            }
        }
    }
    
    func createGarden(authService: AuthService, gardenStore: GardenStore) {
        isLoading = true
        Task {
            defer { isLoading = false }
            validateErrors()
            if (errors.isEmpty) {
                do {
                    _ = try await gardenStore.createGarden(
                        name: name,
                        city: city ?? "Unknown",
                        geoLocation: geoLocation ?? [90,0]
                    )
                    
                    // Dismiss view
                    dismissView = true
                } catch let error as AppError {
                    errors.append(error)
                }
            }
            
            if !errors.isEmpty {
                feedbackTrigger.toggle()
            }
        }
    }
    
    private func validateErrors() {
        errors = []
        validateName()
        validateCity()
    }
    
    private func validateName() {
        if name.isEmpty {
            errors.append(AppError("Name is required.", "name_empty"))
        }
    }
    
    private func validateCity() {
        if city == nil || geoLocation == nil {
            errors.append(AppError("City is required.", "city_empty"))
        }
    }
}
