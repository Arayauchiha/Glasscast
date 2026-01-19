//
//  WeatherAPIService+DataObjects.swift
//  Glasscast
//
//  Created by Aryan Singh on 20/01/26.
//

import Foundation

struct Wind: Codable {
    let speed: Double
    let deg: Int
    let gust: Double?
}

struct Pressure: Codable {
    let press: Int
    let sea_level: Int
    
    enum CodingKeys: String, CodingKey {
        case press, sea_level
    }
}

struct Temperature: Codable {
    let temp: Double
    let temp_kf: Double?
    let temp_max: Double
    let temp_min: Double
    let feels_like: Double
}

struct WeatherData: Codable, Identifiable {
    var id: Int { reference_time }
    let reference_time: Int
    let sunset_time: Int?
    let sunrise_time: Int
    let clouds: Int
    let rain: [String: Double]?
    let snow: [String: Double]?
    let wind: Wind
    let humidity: Int
    let pressure: Pressure
    let temperature: Temperature
    let status: String
    let detailed_status: String
    let weather_code: Int
    let weather_icon_name: String
    let visibility_distance: Int
    let dewpoint: Double?
    let humidex: Double?
    let heat_index: Double?
    let utc_offset: Int?
    let uvi: Double?
    let precipitation_probability: Double?
}

struct CitySearchResult: Identifiable, Codable, Hashable {
    var id: Int { cityId }
    let name: String
    let cityId: Int
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        name = try container.decode(String.self)
        cityId = try container.decode(Int.self)
    }
}

struct AuthRequest: Codable, Sendable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
    let accessToken: String
}

struct CachedCity: Codable, Identifiable {
    let id: Int
    let name: String
    let weather: WeatherData?
    let forecast: [WeatherData]?
    let lastUpdated: Date
    let isFavorite: Bool
}
