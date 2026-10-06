//
//  PlantNetService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 1/10/2026.
//

import Foundation
import Alamofire

class PlantNetService {
    private let baseURL = AppConfig.supabaseURL.appendingPathComponent("functions/v1/plants/identify").absoluteString
    
    func identifyPlant(imageData: Data) async throws -> PlantNetResponse {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "nb-results", value: "4"),
            URLQueryItem(name: "lang", value: "en"),
            URLQueryItem(name: "include-related-images", value: "true")
        ]
        
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        
        let response = try await AF.upload(
            multipartFormData: { multipart in
                // Add the image.
                multipart.append(imageData,
                                 withName: "images",
                                 fileName: "plant.jpg",
                                 mimeType: "image/jpeg")
                
                // Add the organ type.
                if let organData = "auto".data(using: .utf8) {
                    multipart.append(organData, withName: "organs")
                }
            },
            to: finalURL,
            method: .post
        )
        .validate()
        .serializingDecodable(PlantNetResponse.self)
        .value
        
        return response
    }
}
