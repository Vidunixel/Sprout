//
//  OpenMetroResponse.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation

nonisolated struct OpenMeteoResponse: Decodable, Sendable {
    let daily: OpenMeteoDaily
}

nonisolated struct OpenMeteoDaily: Decodable, Sendable {
    let time: [String]
    let temperature2mMax: [Double]
    let precipitationSum: [Double]
    let weatherCode: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case precipitationSum = "precipitation_sum"
        case weatherCode = "weather_code"
    }
}

struct DailyWeatherForecast: Sendable {
    let date: Date
    let maxTemp: Double
    let precipitationSum: Double
    let weatherCode: Int
    
    var isHeavyRain: Bool {
        let heavyRainCodes: Set<Int> = [
            65, // Rain, not freezing, continuous.
            81, // Rain shower(s), moderate or heavy.
            82, // Rain shower(s), violent.
            95, // Thunderstorm, slight or moderate, without hail (but with rain and/or snow at time of observation).
            96, // Thunderstorm, slight or moderate, with hail (at time of observation).
            99 // Thunderstorm, heavy, with hail (at time of observation).
        ]
        
        // >= 10mm precipitation or heavyRainCodes
        return precipitationSum >= 10.0 || heavyRainCodes.contains(weatherCode)
    }
    
    /// Extreme heat: >= 32°C max daily.
    var isExtremeHeat: Bool {
        return maxTemp >= 32.0
    }
}
