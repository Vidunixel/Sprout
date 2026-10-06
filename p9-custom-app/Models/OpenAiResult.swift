//
//  OpenAiResult.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 7/10/2026.
//

import Foundation

nonisolated struct OpenAiResult: Decodable, Sendable {
    let tasks: [PlantCareTask]
}

nonisolated struct PlantCareTask: Decodable, Sendable {
    let taskName: String
    let instructions: String
    let schedule: TaskSchedule
    let weatherAdjustments: WeatherAdjustments
}

nonisolated struct TaskSchedule: Decodable, Sendable {
    let springIntervalDays: Int
    let summerIntervalDays: Int
    let autumnIntervalDays: Int
    let winterIntervalDays: Int
}

nonisolated struct WeatherAdjustments: Decodable, Sendable {
    let heavyRainMultiplier: Double
    let extremeHeatMultiplier: Double
}
