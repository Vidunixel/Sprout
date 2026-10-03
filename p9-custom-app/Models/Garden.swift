//
//  Garden.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 3/10/2026.
//

import Foundation

struct Garden: Codable, Identifiable, Hashable {
    let id: Int
    let createdAt: Date
    let name: String
    let city: String
    let geoLocation: [Double]
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case name
        case city
        case geoLocation = "geo_location"
        case userId = "user_id"
    }
}

struct GardenInsert: Encodable {
    let name: String
    let city: String
    let geoLocation: [Double]
    
    enum CodingKeys: String, CodingKey {
        case name
        case city
        case geoLocation = "geo_location"
    }
}
