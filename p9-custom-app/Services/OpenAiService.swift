//
//  OpenAiService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 7/10/2026.
//

import Foundation
import Alamofire

class OpenAiService {
    // Construct the URL directly from your central AppConfig
    private let baseURL = AppConfig.supabaseURL.appendingPathComponent("functions/v1/plants/analyse").absoluteString
    
    func analysePlant(
        species: String?,
        lightExposure: PlantLightExposure?,
        isIndoors: Bool?,
        potSize: PlantPotSize?,
        city: String?,
        geoLocation: [Double]?
    ) async throws -> OpenAiResult {
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = []
        
        if let species, !species.isEmpty {
            queryItems.append(URLQueryItem(name: "species", value: species))
        }
        if let lightExposure {
            queryItems.append(URLQueryItem(name: "lightExposure", value: lightExposure.rawValue))
        }
        if let isIndoors {
            queryItems.append(URLQueryItem(name: "isIndoors", value: String(isIndoors)))
        }
        if let potSize {
            queryItems.append(URLQueryItem(name: "potSize", value: potSize.rawValue))
        }
        if let city, !city.isEmpty {
            queryItems.append(URLQueryItem(name: "city", value: city))
        }
        if let geoLocation, geoLocation.count >= 2 {
            // Format coordinates as a single string for the query parameter
            let geoString = "\(geoLocation[0]),\(geoLocation[1])"
            queryItems.append(URLQueryItem(name: "geoLocation", value: geoString))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        
        // Use the publishable key defined in AppConfig.swift
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(AppConfig.supabasePublishableKey)"
        ]
        
        let response = try await AF.request(
            finalURL,
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(OpenAiResult.self)
        .value
        
        return response
    }
}
