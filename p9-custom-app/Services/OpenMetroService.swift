//
//  OpenMetroService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation
import Alamofire

class OpenMeteoService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    
    func fetchSevenDayForecast(latitude: Double, longitude: Double) async throws -> [DailyWeatherForecast] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,precipitation_sum,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let response = try await AF.request(url, method: .get)
            .validate()
            .serializingDecodable(OpenMeteoResponse.self)
            .value
            
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        
        var forecasts: [DailyWeatherForecast] = []
        let count = min(
            response.daily.time.count,
            response.daily.temperature2mMax.count,
            response.daily.precipitationSum.count,
            response.daily.weatherCode.count
        )
        
        for i in 0..<count {
            if let date = formatter.date(from: response.daily.time[i]) {
                forecasts.append(
                    DailyWeatherForecast(
                        date: Calendar.current.startOfDay(for: date),
                        maxTemp: response.daily.temperature2mMax[i],
                        precipitationSum: response.daily.precipitationSum[i],
                        weatherCode: response.daily.weatherCode[i]
                    )
                )
            }
        }
        
        return forecasts
    }
}
