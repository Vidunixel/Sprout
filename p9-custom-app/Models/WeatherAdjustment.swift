//
//  WeatherAdjustment.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation

struct WeatherAdjustment: Codable, Identifiable, Hashable {
    let id: Int
    let taskId: Int
    let name: String
    let createdAt: Date
    let multiplier: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case name
        case createdAt = "created_at"
        case multiplier
    }
}

struct WeatherAdjustmentInsert: Encodable {
    let taskId: Int
    let name: String
    let multiplier: Double
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case name
        case multiplier
    }
}
