//
//  Plant.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation

enum PlantLightExposure: String, Codable, CaseIterable, Identifiable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    var id: Self { self }
}

enum PlantPotSize: String, Codable, CaseIterable, Identifiable {
    case mini = "MINI"
    case small = "SMALL"
    case medium = "MEDIUM"
    case large = "LARGE"
    
    var id: Self { self }
}

struct Plant: Codable, Identifiable, Hashable {
    let id: Int
    let createdAt: Date
    let userId: UUID
    let species: String
    let name: String
    let lightExposure: PlantLightExposure
    var isIndoors: Bool = true
    var potSize: PlantPotSize? = nil
    let gardenId: Int
    var tasks: [TaskModel]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case userId = "user_id"
        case species
        case name
        case lightExposure = "light_exposure"
        case isIndoors = "is_indoors"
        case potSize = "pot_size"
        case gardenId = "garden_id"
        case tasks
    }
}

struct PlantInsert: Encodable {
    let userId: UUID
    let species: String
    let name: String
    let lightExposure: PlantLightExposure
    var isIndoors: Bool = true
    var potSize: PlantPotSize? = nil
    let gardenId: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case species
        case name
        case lightExposure = "light_exposure"
        case isIndoors = "is_indoors"
        case potSize = "pot_size"
        case gardenId = "garden_id"
    }
}
