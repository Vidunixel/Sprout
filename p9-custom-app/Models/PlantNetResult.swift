//
//  PlantNetResponse.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 1/10/2026.
//

import Foundation

nonisolated struct PlantNetResponse: Decodable, Sendable {
    let bestMatch: String
    let results: [PlantNetResult]
}

nonisolated struct PlantNetResult: Decodable, Identifiable, Hashable, Sendable {
    let score: Double
    let species: Species
    let images: [PlantImage]
    
    var id: String {
        species.scientificNameWithoutAuthor
    }
}

nonisolated struct PlantImage: Decodable, Hashable, Sendable {
    let url: ImageSize
}

nonisolated struct ImageSize: Decodable, Hashable, Sendable {
    let o: URL?
    let m: URL?
    let s: URL?
}

nonisolated struct Species: Decodable, Hashable, Sendable {
    let scientificNameWithoutAuthor: String
    let commonNames: [String]
}
