//
//  WeatherViewModel.swift
//  Glasscast
//
//  Created by Aryan Singh on 20/01/26.
//

internal import Combine
import Foundation


class WeatherViewModel: ObservableObject {
    var objectWillChange: ObservableObjectPublisher
    
    @Published var currentCity: CachedCity?
    @Published var favoriteCities: [CachedCity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var citySuggestions: [CitySearchResult] = []
    
    private let api = WeatherAPIService.shared
    private let cache = CacheManager.shared
    
    init() {
        let cached = cache.loadCities()
        favoriteCities = cached.filter { $0.isFavorite }
        currentCity = cached.first { !$0.isFavorite }
        objectWillChange = .init()
    }
    
    func searchAndSetCity(name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await api.searchCity(name: name)
            if let first = results.first {
                await loadCityData(id: first.cityId, name: first.name, isFavorite: false)
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadCityData(id: Int, name: String, isFavorite: Bool) async {
        isLoading = true
        
        do {
            async let weatherData = api.getWeather(cityId: id)
            async let forecastData = api.getForecast(cityId: id)
            
            let (weather, forecast) = try await (weatherData, forecastData)
            
            let city = CachedCity(
                id: id,
                name: name,
                weather: weather,
                forecast: forecast,
                lastUpdated: Date(),
                isFavorite: isFavorite
            )
            
            await MainActor.run {
                if isFavorite {
                    if let index = favoriteCities.firstIndex(where: { $0.id == id }) {
                        favoriteCities[index] = city
                    } else {
                        favoriteCities.append(city)
                    }
                } else {
                    currentCity = city
                }
                saveCachedData()
            }
        } catch {
            errorMessage = "Failed to load weather: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addToFavorites(id: Int, name: String) async {
        do {
            try await api.addFavorite(cityId: id)
            await loadCityData(id: id, name: name, isFavorite: true)
        } catch {
            errorMessage = "Failed to add favorite"
        }
    }
    
    func saveCachedData() {
        var allCities = favoriteCities
        if let current = currentCity {
            allCities.append(current)
        }
        cache.saveCities(allCities)
    }
    
    func fetchSuggestions(for query: String) async {
        guard !query.isEmpty else {
            citySuggestions = []
            return
        }
        
        let result: [CitySearchResult]? = try? await api.searchCity(name: query)
        citySuggestions = result ?? []
    }
}
