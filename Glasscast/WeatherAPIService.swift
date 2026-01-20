//
//  WeatherAPIService.swift
//  Glasscast
//
//  Created by Aryan Singh on 20/01/26.
//

internal import Combine
import Foundation

private let baseURLString = "http://13.203.42.179:6969/v1"

enum Endpoint: String {
    case create = "/auth/create"
    case login = "/auth/login"
    
    case search = "/data/search/%@"
    case weather = "/data/weather/%@"
    case forecast = "/data/forecast/%@"
    case addFavorite = "/data/add_favorite/%@"
    case favorites = "/data/favorites"
}

extension Endpoint {
    var urlString: String {
        return baseURLString + rawValue
    }
    
    func urlString(with parameters: String...) -> String {
        return String(format: urlString, arguments: parameters)
    }
}

class WeatherAPIService: ObservableObject {
    static let shared = WeatherAPIService()

    func register(email: String, password: String) async throws {
        let url: Endpoint = .create
        
        return try await makeRequest(url: url, email: email, password: password)
    }

    func login(email: String, password: String) async throws {
        let url: Endpoint = .login
        return try await makeRequest(url: url, email: email, password: password)
    }
    
    private func makeRequest(url: Endpoint, email: String, password: String) async throws {
        let request = AuthRequest(email: email, password: password)
        guard let data = try? request.toData() else {
            fatalError()
        }
        guard let response: AuthResponse? = await NetworkManager.shared.post(url: url.urlString, body: data) else {
            fatalError()
        }
        
        let accessToken = response?.accessToken
        if let accessToken {
            KeychainHelper.set(accessToken, forKey: "accessToken")
        }
    }
    
    func searchCity(name: String) async throws -> [CitySearchResult] {
        let cityName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let url: String = Endpoint.search.urlString(with: cityName)
        
        let cities: [CitySearchResult]? = await NetworkManager.shared.get(url: url)
        
        return cities ?? []
    }
    
    func getWeather(cityId: Int) async throws -> WeatherData? {
        let url: String = Endpoint.weather.urlString(with: String(cityId))
        return await NetworkManager.shared.get(url: url)
    }
    
    func getForecast(cityId: Int) async throws -> [WeatherData] {
        let url: String = Endpoint.forecast.urlString(with: String(cityId))
        let forecast: [WeatherData]? = await NetworkManager.shared.get(url: url)
        return forecast ?? []
    }
    
    func addFavorite(cityId: Int) async throws {
        let url: String = Endpoint.addFavorite.urlString(with: String(cityId))
        let _: Bool? = await NetworkManager.shared.get(url: url)
    }
    
    func fetchFavorites() async throws -> [Int] {
        let url: String = Endpoint.favorites.urlString
        let cityIds: [Int]? = await NetworkManager.shared.get(url: url)
        return cityIds ?? []
    }

    func logout() {
        KeychainHelper.remove("accessToken")
    }
}
