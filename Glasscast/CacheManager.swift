//
//  CacheManager.swift
//  Glasscast
//
//  Created by Aryan Singh on 20/01/26.
//

import Foundation


class CacheManager {
    static let shared = CacheManager()
    private let cacheKey = "cached_cities"
    
    func saveCities(_ cities: [CachedCity]) {
        if let encoded = try? JSONEncoder().encode(cities) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    func loadCities() -> [CachedCity] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cities = try? JSONDecoder().decode([CachedCity].self, from: data) else {
            return []
        }
        return cities
    }
}
