//
//  Task.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation

struct TaskModel: Codable, Identifiable, Hashable {
    let id: Int
    let plantId: Int
    let createdAt: Date
    let name: String
    let instructions: String
    var springIntervalDays: Int?
    var summerIntervalDays: Int?
    var autumnIntervalDays: Int?
    var winterIntervalDays: Int?
    var currentCycle: Int = 1
    var weatherAdjustments: [WeatherAdjustment]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case plantId = "plant_id"
        case createdAt = "created_at"
        case name
        case instructions
        case springIntervalDays = "spring_interval_days"
        case summerIntervalDays = "summer_interval_days"
        case autumnIntervalDays = "autumn_interval_days"
        case winterIntervalDays = "winter_interval_days"
        case currentCycle = "current_cycle"
        case weatherAdjustments = "weather_adjustments"
    }
}

struct TaskInsert: Encodable {
    let plantId: Int
    let name: String
    let instructions: String
    var springIntervalDays: Int?
    var summerIntervalDays: Int?
    var autumnIntervalDays: Int?
    var winterIntervalDays: Int?
    var currentCycle: Int = 1
    
    enum CodingKeys: String, CodingKey {
        case plantId = "plant_id"
        case name
        case instructions
        case springIntervalDays = "spring_interval_days"
        case summerIntervalDays = "summer_interval_days"
        case autumnIntervalDays = "autumn_interval_days"
        case winterIntervalDays = "winter_interval_days"
        case currentCycle = "current_cycle"
    }
}
