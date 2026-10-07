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
        species: String,
        lightExposure: PlantLightExposure,
        isIndoors: Bool,
        potSize: PlantPotSize?,
        city: String,
        geoLocation: [Double]
    ) async throws -> OpenAiResult {
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "species", value: species),
            URLQueryItem(name: "lightExposure", value: lightExposure.rawValue),
            URLQueryItem(name: "isIndoors", value: String(isIndoors)),
            URLQueryItem(name: "city", value: city)
        ]
        
        if let potSize {
            queryItems.append(URLQueryItem(name: "potSize", value: potSize.rawValue))
        }
        if geoLocation.count == 2 {
            // Format coordinates as a single string for the query parameter
            let geoString = "[\(geoLocation[0]),\(geoLocation[1])]"
            queryItems.append(URLQueryItem(name: "geoLocation", value: geoString))
        }
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        
        let response = try await AF.request(
            finalURL,
            method: .get
        )
        .validate()
        .serializingDecodable(OpenAiResult.self)
        .value
        
        return response
    }
}
