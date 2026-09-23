//
//  AppError.swift
//  p5-lab6
//
//  Created by Vidun Herath on 15/9/2026.
//

import Foundation

enum AppError: LocalizedError {
    case invalidForm(String)
    
    var errorDescription: String? {
        switch self {
            case .invalidForm(let message): message
        }
    }
    
    var nsError: NSError {
        NSError(
            domain: "Sprout",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: errorDescription ?? "An unknown error occured."]
        )
    }
}
