import SwiftUI
import CoreLocation
internal import Combine

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius
    case fahrenheit
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

struct SettingsView: View {
    @AppStorage("tempUnit") private var tempUnitRaw = TemperatureUnit.celsius.rawValue
    @Binding var isAuthenticated: Bool
    
    private var tempUnit: Binding<TemperatureUnit> {
        Binding(
            get: { TemperatureUnit(rawValue: tempUnitRaw) ?? .celsius },
            set: { tempUnitRaw = $0.rawValue }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                // 🌡 Temperature Section
                Section(header: Text("Temperature")) {
                    Picker("Unit", selection: tempUnit) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // 🔐 Account Section
                Section {
                    Button(role: .destructive) {
                        signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func signOut() {
        KeychainHelper.remove("accessToken")
        isAuthenticated = false
    }
}

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLogin = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.6), .orange.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white, .yellow)
                
                Text("Weather")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    SecureField("Password", text: $password)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Button {
                        authenticate()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(isLogin ? "Login" : "Register")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button {
                        isLogin.toggle()
                    } label: {
                        Text(isLogin
                             ? "Need an account? Register"
                             : "Have an account? Login")
                        .font(.footnote)
                    }
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func authenticate() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isLogin {
                    try await WeatherAPIService.shared.login(email: email, password: password)
                } else {
                    try await WeatherAPIService.shared.register(email: email, password: password)
                    try await WeatherAPIService.shared.login(email: email, password: password)
                }
                
                await MainActor.run {
                    isAuthenticated = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}


struct WeatherCardView: View {
    let city: CachedCity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            temperature
            details
            forecast
        }
        .padding()
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(city.name)
                    .font(.title2.bold())
                
                Text(city.weather?.detailed_status.capitalized ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: weatherIcon(for: city.weather?.weather_icon_name ?? ""))
                .font(.system(size: 48))
        }
    }
    
    private var temperature: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(Int(city.weather!.temperature.temp - 273.15))°")
                .font(.system(size: 64, weight: .thin))
            
            VStack(alignment: .leading) {
                Text("Feels like \(Int(city.weather!.temperature.feels_like - 273.15))°")
                Text("H:\(Int(city.weather!.temperature.temp_max - 273.15))°  L:\(Int(city.weather!.temperature.temp_min - 273.15))°")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    private var details: some View {
        HStack {
            WeatherDetailItem(icon: "drop.fill", value: "\(city.weather!.humidity)%", label: "Humidity")
            WeatherDetailItem(icon: "wind", value: "\(Int(city.weather!.wind.speed)) m/s", label: "Wind")
            WeatherDetailItem(icon: "eye.fill", value: "\(city.weather!.visibility_distance / 1000) km", label: "Visibility")
        }
    }
    
    private var forecast: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(city.forecast?.prefix(8) ?? []) {
                    ForecastItem(weather: $0)
                }
            }
        }
    }
    
    private func weatherIcon(for code: String) -> String {
        switch code {
        case let c where c.contains("01"): "sun.max.fill"
        case let c where c.contains("02"): "cloud.sun.fill"
        case let c where c.contains("03"), let c where c.contains("04"): "cloud.fill"
        case let c where c.contains("09"), let c where c.contains("10"): "cloud.rain.fill"
        case let c where c.contains("11"): "cloud.bolt.fill"
        case let c where c.contains("13"): "cloud.snow.fill"
        case let c where c.contains("50"): "cloud.fog.fill"
        default: "cloud.fill"
        }
    }
}

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ForecastItem: View {
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formatTime(weather.reference_time))
                .font(.caption)
            
            Image(systemName: "cloud.fill")
                .font(.title3)
            
            Text("\(Int(weather.temperature.temp - 273.15))°")
                .font(.caption)
                .bold()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    func formatTime(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Current Weather View
struct CurrentWeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let city = viewModel.currentCity {
                        WeatherCardView(city: city)
                            .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                await viewModel.addToFavorites(id: city.id, name: city.name)
                            }
                        }) {
                            Label("Add to Favorites", systemImage: "star")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Search for a city to see weather")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Weather")
            .searchable(text: $searchText, isPresented: $isSearching)
            .searchSuggestions {
                ForEach(viewModel.citySuggestions, id: \.self) { result in
                    Text(result.name)
                        .searchCompletion(result.name)
                }
            }
            .onChange(of: searchText) {
                Task { await viewModel.fetchSuggestions(for: searchText) }
            }
            .onSubmit(of: .search) {
                Task {
                    await viewModel.searchAndSetCity(name: searchText)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        locationManager.requestLocation()
                    }) {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct FavoritesView: View {
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.favoriteCities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No favorite cities yet")
                            .foregroundColor(.secondary)
                        Text("Add cities from the weather tab")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(viewModel.favoriteCities) { city in
                                WeatherCardView(city: city)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            for city in viewModel.favoriteCities {
                                await viewModel.loadCityData(id: city.id, name: city.name, isFavorite: true)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var isAuthenticated = false
    
    init() {
        _isAuthenticated = State(initialValue: KeychainHelper.get("accessToken") != nil)
    }
    
    var body: some View {
        if isAuthenticated {
            TabView {
                CurrentWeatherView()
                    .tabItem {
                        Label("Weather", systemImage: "cloud.sun.fill")
                    }
                
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                
                SettingsView(isAuthenticated: $isAuthenticated)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
        } else {
            AuthView(isAuthenticated: $isAuthenticated)
        }
    }
}
