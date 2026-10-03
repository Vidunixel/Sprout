//
//  AddGardenViewModel.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 4/10/2026.
//

import SwiftUI
import Observation
internal import MapKit

@Observable
@MainActor
class AddGardenViewModel {
    var name = ""
    var city = ""
    var geoLocation: [Int]?
    var isLoading = false
    var errors: [AppError] = []
    var feedbackTrigger = false
    
    var cityCompleter = LocalityAutocomplete()
    var cityResults: [MKLocalSearchCompletion] = []
}
