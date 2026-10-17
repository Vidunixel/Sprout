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
    private let baseURL = AppConfig.supabaseURL.appendingPathComponent("functions/v1/plants")
    
    func analysePlant(
        species: String,
        lightExposure: PlantLightExposure,
        isIndoors: Bool,
        potSize: PlantPotSize?,
        city: String,
        geoLocation: [Double]
    ) async throws -> PlantAnalysisResult {
        var components = URLComponents(url: baseURL.appendingPathComponent("analyse"), resolvingAgainstBaseURL: false)!
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
            // Format coordinates as a single string for the query parameter.
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
        .serializingDecodable(PlantAnalysisResult.self)
        .value
        
        return response
    }
    
    func generatePlantModel(imageData: Data, potSize: PlantPotSize?) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent("3d"), resolvingAgainstBaseURL: false)!
        
        if let potSize {
            components.queryItems = [URLQueryItem(name: "potSize", value: potSize.rawValue)]
        }
        
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        
        // Fetch a USDZ model of the plant.
        let usdzData = try await AF.upload(
            multipartFormData: { multipart in
                multipart.append(imageData,
                                 withName: "image",
                                 fileName: "plant.jpg",
                                 mimeType: "image/jpeg")
            },
            to: finalURL,
            method: .post
        )
        .validate()
        .serializingData()
        .value
        
        return usdzData
    }
}
