//
//  WeatherEvaluationService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation
import Supabase

@MainActor
final class WeatherEvaluationService {
    private let openMeteoService = OpenMeteoService()
    
    /// Evaluates weather forecasts for all gardens and inserts timeline adjustments if thresholds are met.
    func evaluateAndSync(gardens: [Garden]) async -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        var didInsertAnyTimeline = false
        
        for garden in gardens {
            guard garden.geoLocation.count == 2 else { continue }
            let latitude = garden.geoLocation[0]
            let longitude = garden.geoLocation[1]
            
            // Fetch 7-day forecast.
            guard let forecasts = try? await openMeteoService.fetchSevenDayForecast(latitude: latitude, longitude: longitude),
                  let lastForecastDate = forecasts.map(\.date).max() else {
                continue
            }
            
            for plant in garden.plants ?? [] {
                for task in plant.tasks ?? [] {
                    guard let baseDue = task.baseDueDate(latitude: latitude) else { continue }
                    let baseDueStart = calendar.startOfDay(for: baseDue)
                    
                    // Only check tasks whose unadjusted base due date falls within the 7-day window.
                    guard baseDueStart >= todayStart && baseDueStart <= lastForecastDate else { continue }
                    
                    // Filter forecast days between today and the base due date.
                    let relevantForecasts = forecasts.filter { $0.date >= todayStart && $0.date <= baseDueStart }
                    guard !relevantForecasts.isEmpty else { continue }
                    
                    for adjustment in task.weatherAdjustments ?? [] where adjustment.multiplier != 1.0 {
                        // Skip if a timeline entry already exists for the current cycle.
                        let alreadyRecorded = adjustment.timelines?.contains(where: { $0.cycle == task.currentCycle }) ?? false
                        if alreadyRecorded { continue }
                        
                        let conditionMet: Bool
                        switch adjustment.name {
                        case "heavyRainMultiplier":
                            conditionMet = relevantForecasts.contains(where: \.isHeavyRain)
                        case "extremeHeatMultiplier":
                            conditionMet = relevantForecasts.contains(where: \.isExtremeHeat)
                        default:
                            conditionMet = false
                        }
                        
                        if conditionMet {
                            let newTimeline = WeatherAdjustmentTimelineInsert(
                                weatherAdjustmentId: adjustment.id,
                                cycle: task.currentCycle
                            )
                            
                            do {
                                try await supabase
                                    .from("weather_adjustments_timeline")
                                    .insert(newTimeline)
                                    .execute()
                                didInsertAnyTimeline = true
                            } catch {
                                print("Failed to insert weather adjustment timeline: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        
        return didInsertAnyTimeline
    }
}
