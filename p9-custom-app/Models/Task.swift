//
//  Task.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 6/10/2026.
//

import Foundation
import SwiftUI

enum Season {
    case spring, summer, autumn, winter
    
    static func current(for date: Date = .now, latitude: Double? = nil) -> Season {
        let month = Calendar.current.component(.month, from: date)
        let isSouthernHemisphere = (latitude ?? -37.8) < 0
        
        switch month {
        case 3...5:
            return isSouthernHemisphere ? .autumn : .spring
        case 6...8:
            return isSouthernHemisphere ? .winter : .summer
        case 9...11:
            return isSouthernHemisphere ? .spring : .autumn
        default:
            return isSouthernHemisphere ? .summer : .winter
        }
    }
}

struct TaskModel: Codable, Identifiable, Hashable {
    let id: Int
    let plantId: Int
    let createdAt: Date
    let name: String
    var sfSymbol: String?
    var sfSymbolColour: String?
    let instructions: String
    var springIntervalDays: Int?
    var summerIntervalDays: Int?
    var autumnIntervalDays: Int?
    var winterIntervalDays: Int?
    var currentCycle: Int = 1
    var weatherAdjustments: [WeatherAdjustment]?
    var taskLogs: [TaskLog]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case plantId = "plant_id"
        case createdAt = "created_at"
        case name
        case sfSymbol = "sf_symbol"
        case sfSymbolColour = "sf_symbol_colour"
        case instructions
        case springIntervalDays = "spring_interval_days"
        case summerIntervalDays = "summer_interval_days"
        case autumnIntervalDays = "autumn_interval_days"
        case winterIntervalDays = "winter_interval_days"
        case currentCycle = "current_cycle"
        case weatherAdjustments = "weather_adjustments"
        case taskLogs = "tasks_log"
    }
    
    var symbolColor: Color {
        switch sfSymbolColour?.lowercased() {
        case "blue": return .blue
        case "brown": return .brown
        case "cyan": return .cyan
        case "gray": return .gray
        case "green": return .green
        case "indigo": return .indigo
        case "mint": return .mint
        case "orange": return .orange
        case "pink": return .pink
        case "purple": return .purple
        case "red": return .red
        case "teal": return .teal
        case "yellow": return .yellow
        default: return .green // Fallback color
        }
    }
    
    func intervalDays(for date: Date = .now, latitude: Double? = nil) -> Int? {
        switch Season.current(for: date, latitude: latitude) {
        case .spring:
            return springIntervalDays
        case .summer:
            return summerIntervalDays
        case .autumn:
            return autumnIntervalDays
        case .winter:
            return winterIntervalDays
        }
    }
    
    var cycleStartDate: Date {
        if currentCycle == 1 {
            return createdAt
        } else if let latestLog = taskLogs?.max(by: { $0.cycle < $1.cycle }) {
            return latestLog.createdAt
        }
        return createdAt
    }
    
    /// Due date without any weather adjustments.
    func baseDueDate(latitude: Double? = nil) -> Date? {
        guard let baseInterval = intervalDays(latitude: latitude), baseInterval > 0 else {
            return nil
        }
        return Calendar.current.date(byAdding: .day, value: baseInterval, to: cycleStartDate)
    }
    
    /// Due date with weather adjustments.
    func dueDate(latitude: Double? = nil) -> Date? {
        guard let baseInterval = intervalDays(latitude: latitude), baseInterval > 0 else {
            return nil
        }
        
        var combinedMultiplier = 1.0 // Combine multiple weather adjustments.
        if let adjustments = weatherAdjustments {
            // Apply weather adjustments.
            for adjustment in adjustments where adjustment.multiplier != 1.0 {
                let isTriggeredForCurrentCycle = adjustment.timelines?.contains(where: { $0.cycle == currentCycle }) ?? false
                if isTriggeredForCurrentCycle {
                    combinedMultiplier *= adjustment.multiplier
                }
            }
        }
        
        let adjustedDays = Int((Double(baseInterval) * combinedMultiplier).rounded())
        return Calendar.current.date(byAdding: .day, value: adjustedDays, to: cycleStartDate)
    }
    
    // Return due date at 9am.
    func notificationDate(latitude: Double? = nil) -> Date? {
        guard let due = dueDate(latitude: latitude) else { return nil }
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: due)
    }
    
    func daysUntilDue(latitude: Double? = nil) -> Int? {
        guard let finalDue = dueDate(latitude: latitude) else { return nil }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: .now)
        let dueStart = calendar.startOfDay(for: finalDue)
        return calendar.dateComponents([.day], from: todayStart, to: dueStart).day
    }
    
    func dueStatusText(latitude: Double? = nil) -> String {
        guard let days = daysUntilDue(latitude: latitude) else {
            return "Inactive"
        }
        
        if days == 0 {
            return "Due today"
        } else if days < 0 {
            let overdueDays = abs(days)
            return "\(overdueDays) \(overdueDays == 1 ? "day" : "days") overdue"
        } else {
            return "In \(days) \(days == 1 ? "day" : "days")"
        }
    }
    
    var activeAdjustments: [WeatherAdjustment] {
        guard let adjustments = weatherAdjustments else { return [] }
        return adjustments.filter { adjustment in
            adjustment.timelines?.contains(where: { $0.cycle == currentCycle }) ?? false
        }
    }
    
    var appliedConditions: String {
        activeAdjustments.map { adjustment in
            switch adjustment.name {
            case "heavyRainMultiplier": return "Heavy Rain"
            case "extremeHeatMultiplier": return "Extreme Heat"
            default: return adjustment.name
            }
        }.joined(separator: ", ")
    }
}

struct TaskInsert: Encodable {
    let plantId: Int
    let name: String
    var sfSymbol: String?
    var sfSymbolColour: String?
    let instructions: String
    var springIntervalDays: Int?
    var summerIntervalDays: Int?
    var autumnIntervalDays: Int?
    var winterIntervalDays: Int?
    var currentCycle: Int = 1
    
    enum CodingKeys: String, CodingKey {
        case plantId = "plant_id"
        case name
        case sfSymbol = "sf_symbol"
        case sfSymbolColour = "sf_symbol_colour"
        case instructions
        case springIntervalDays = "spring_interval_days"
        case summerIntervalDays = "summer_interval_days"
        case autumnIntervalDays = "autumn_interval_days"
        case winterIntervalDays = "winter_interval_days"
        case currentCycle = "current_cycle"
    }
}
