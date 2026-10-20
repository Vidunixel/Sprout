//
//  WeatherAdjustmentTimeline.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation

struct WeatherAdjustmentTimeline: Codable, Identifiable, Hashable {
    let weatherAdjustmentId: Int
    let cycle: Int
    let createdAt: Date
    
    // Computed property for Identifiable conformance using the composite primary key
    var id: String {
        "\(weatherAdjustmentId)_\(cycle)"
    }
    
    enum CodingKeys: String, CodingKey {
        case weatherAdjustmentId = "weather_adjustment_id"
        case cycle
        case createdAt = "created_at"
    }
}

struct WeatherAdjustmentTimelineInsert: Encodable {
    let weatherAdjustmentId: Int
    let cycle: Int
    
    enum CodingKeys: String, CodingKey {
        case weatherAdjustmentId = "weather_adjustment_id"
        case cycle
    }
}
