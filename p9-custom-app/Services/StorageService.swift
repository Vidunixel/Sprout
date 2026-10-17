//
//  StorageService.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 17/10/2026.
//

import Foundation
import Supabase

class StorageService {
    func uploadPlantImage(data: Data, userId: UUID, plantId: Int) async throws {
        let filePath = "\(userId.uuidString.lowercased())/\(plantId).jpg"
        try await supabase.storage
            .from("plants")
            .upload(
                filePath,
                data: data,
                options: FileOptions(contentType: "image/jpeg")
            )
    }
    
    func uploadPlantModel(data: Data, userId: UUID, plantId: Int) async throws {
        let filePath = "\(userId.uuidString.lowercased())/\(plantId).usdz"
        try await supabase.storage
            .from("plant-models")
            .upload(
                filePath,
                data: data,
                options: FileOptions(contentType: "model/vnd.usdz+zip")
            )
    }
    
    func downloadPlantModel(userId: UUID, plantId: Int) async throws -> Data {
        let path = "\(userId.uuidString.lowercased())/\(plantId).usdz"
        return try await supabase.storage
            .from("plant-models")
            .download(path: path)
    }
}
