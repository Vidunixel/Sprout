//
//  AppError.swift
//  p5-lab6
//
//  Created by Vidun Herath on 15/9/2026.
//

import Foundation

struct AppError: LocalizedError {
    var description: String
    var errorCode: String? = nil
    var showAlert: Bool = false
    
    var errorDescription: String? {
        return description
    }
    
    init(_ description: String, _ errorCode: String? = nil, showAlert: Bool? = false) {
        self.description = description
        self.errorCode = errorCode
        self.showAlert = showAlert ?? false
    }
}
