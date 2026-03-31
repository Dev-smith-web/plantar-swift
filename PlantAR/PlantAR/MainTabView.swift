import SwiftUI
import Combine
import RealityKit
import ARKit
import CoreLocation
import PhotosUI
import WebKit
import UserNotifications

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var cityName: String = "your area"
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                DispatchQueue.main.async { self?.cityName = city }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] \(error.localizedDescription)")
    }
}

// MARK: - Hardiness Map WebView (for API HTML content)

struct HardinessMapWebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

// MARK: - Plant Image View (Fetches from Perenual API)

struct PlantImageView: View {
    let plant: Plant
    var size: CGFloat = 140
    var cornerRadius: CGFloat = 0

    @State private var imageURL: String? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Background color
            Rectangle()
                .fill(Color(hex: plant.color).opacity(0.2))

            if let urlString = imageURL ?? plant.imageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        // Fallback to placeholder on error
                        placeholderView
                    case .empty:
                        ProgressView()
                            .tint(Color(hex: plant.color))
                    @unknown default:
                        placeholderView
                    }
                }
            } else if isLoading {
                ProgressView()
                    .tint(Color(hex: plant.color))
            } else {
                placeholderView
            }
        }
        .frame(height: size)
        .clipped()
        .cornerRadius(cornerRadius)
        .onAppear {
            if plant.imageURL == nil && imageURL == nil {
                fetchImageFromAPI()
            }
        }
    }

    private var placeholderView: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size * 0.4))
            .foregroundColor(Color(hex: plant.color))
    }

    private func fetchImageFromAPI() {
        isLoading = true
        Task {
            do {
                // Use commonName for search (scientific names return premium-only images)
                let results = try await PlantAPIService.shared.searchPlants(query: plant.commonName)
                // Find first result with a valid image (not upgrade_access)
                if let validResult = results.first(where: { result in
                    if let imgURL = result.defaultImage?.mediumURL ?? result.defaultImage?.smallURL {
                        return !imgURL.contains("upgrade_access")
                    }
                    return false
                }),
                   let imgURL = validResult.defaultImage?.mediumURL ?? validResult.defaultImage?.smallURL {
                    await MainActor.run {
                        self.imageURL = imgURL
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Main Navigation Shell

struct MainTabView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var persistence: PersistenceService
    @State private var selectedTab: Int = 0
    @State private var showCompleteProfile = false

    private var profileIncomplete: Bool {
        (auth.currentStudentName ?? "").trimmingCharacters(in: .whitespaces).isEmpty ||
        auth.classCode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            IdentifyTab()
                .environmentObject(auth)
                .environmentObject(persistence)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "questionmark.circle.fill" : "questionmark.circle")
                    Text("Identify")
                }
                .tag(0)

            ExploreTab()
                .environmentObject(auth)
                .environmentObject(persistence)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    Text("Explore")
                }
                .tag(1)

            GardenTab()
                .environmentObject(auth)
                .environmentObject(persistence)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                    Text("Garden")
                }
                .tag(2)

            SettingsTab()
                .environmentObject(auth)
                .environmentObject(persistence)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(.plantPrimary)
        .sheet(isPresented: $showCompleteProfile) {
            CompleteProfileView()
                .environmentObject(auth)
                .interactiveDismissDisabled(true)
        }
        .onAppear {
            showCompleteProfile = profileIncomplete
        }
        .onChange(of: auth.currentStudentName) { _, _ in
            showCompleteProfile = profileIncomplete
        }
        .onChange(of: auth.classCode) { _, _ in
            showCompleteProfile = profileIncomplete
        }
    }
}

// MARK: - Complete Profile Sheet

struct CompleteProfileView: View {
    @EnvironmentObject var auth: AuthService
    @State private var name = ""
    @State private var classCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && classCode.count == 6
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PlantSpacing.xxl) {
                    VStack(alignment: .leading, spacing: PlantSpacing.sm) {
                        Text("Complete Your Profile")
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)
                        Text("Your name and class code are missing. Please fill them in to continue.")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, PlantSpacing.lg)

                    VStack(spacing: PlantSpacing.lg) {
                        FormField(
                            title: "Your Name",
                            placeholder: "Enter your full name",
                            icon: "person.fill",
                            text: $name
                        )
                        FormField(
                            title: "Class Code",
                            placeholder: "6-digit code from teacher",
                            icon: "number",
                            text: $classCode,
                            autocapitalization: .characters,
                            characterLimit: 6
                        )
                    }

                    if !errorMessage.isEmpty {
                        HStack(spacing: PlantSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.botanicalError)
                            Text(errorMessage)
                                .font(.bodySmall)
                                .foregroundColor(.botanicalError)
                            Spacer()
                        }
                        .padding(PlantSpacing.md)
                        .background(Color.botanicalError.opacity(0.1))
                        .cornerRadius(PlantRadius.sm)
                    }

                    Spacer(minLength: PlantSpacing.xxl)

                    Button(action: save) {
                        HStack(spacing: PlantSpacing.sm) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save & Continue")
                                Image(systemName: "arrow.right")
                            }
                        }
                    }
                    .buttonStyle(PlantPrimaryButtonStyle(isEnabled: isFormValid && !isLoading))
                    .disabled(!isFormValid || isLoading)
                }
                .padding(.horizontal, PlantSpacing.xl)
                .padding(.bottom, PlantSpacing.xxl)
            }
            .background(Color.pageBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func save() {
        isLoading = true
        errorMessage = ""
        Task {
            do {
                try await auth.updateProfile(name: name, classCode: classCode)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Identify Tab (Merlin-Style Main Screen)

struct IdentifyTab: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var persistence: PersistenceService
    @State private var showARScanner = false
    @State private var showPlantInfo = false
    @State private var showStepByStep = false
    @State private var showPhotoIdentify = false

    var plantOfTheDay: Plant {
        getPlantOfTheDay()
    }

    var discoveredCount: Int {
        persistence.myGarden.filter { $0.studentID == auth.currentStudentID }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Logo Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.plantPrimary)
                        Text("PlantAR")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // Plant of the Day Hero Card - BIGGER (55% of screen)
                PlantOfTheDayHeroBig(
                    plant: plantOfTheDay,
                    onTap: { showPlantInfo = true }
                )

                // Stats divider
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)

                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.5))
                        Text("\(discoveredCount) plants discovered")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(white: 0.5))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 12)

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)

                // Action Buttons Row - Same size, shifted down
                HStack(spacing: 24) {
                    // Step by Step Button (Left) - Gray
                    ActionCircleButton(
                        icon: "list.clipboard.fill",
                        label: "Step by Step",
                        isPrimary: false,
                        action: { showStepByStep = true }
                    )

                    // Scan Button (Center - Primary Green)
                    ActionCircleButton(
                        icon: "camera.viewfinder",
                        label: "Scan",
                        isPrimary: true,
                        action: { showARScanner = true }
                    )

                    // Photo Button (Right) - Gray
                    ActionCircleButton(
                        icon: "photo.fill",
                        label: "Photo",
                        isPrimary: false,
                        action: { showPhotoIdentify = true }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 50)
            }
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.95))
        .fullScreenCover(isPresented: $showARScanner) {
            ARScanView()
                .environmentObject(persistence)
                .environmentObject(auth)
        }
        .fullScreenCover(isPresented: $showPlantInfo) {
            PlantDetailView(plant: plantOfTheDay)
                .environmentObject(persistence)
                .environmentObject(auth)
        }
        .sheet(isPresented: $showStepByStep) {
            StepByStepView()
                .environmentObject(persistence)
                .environmentObject(auth)
        }
        .sheet(isPresented: $showPhotoIdentify) {
            PhotoIdentifyView()
                .environmentObject(persistence)
                .environmentObject(auth)
        }
    }
}

// MARK: - Scanned Plants View (My Sound Recordings equivalent)

struct ScannedPlantsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService

    var studentGarden: [GardenRecord] {
        persistence.myGarden.filter { $0.studentID == auth.currentStudentID }
    }

    var scannedPlants: [Plant] {
        studentGarden.compactMap { record in
            plantDatabase.first { $0.id == record.plantID }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if scannedPlants.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.textTertiary)

                        Text("No Plants Scanned Yet")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        Text("Use the Scan button to identify plants and they'll appear here.")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(scannedPlants) { plant in
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: plant.color).opacity(0.15))
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: plant.color))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plant.commonName)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.textPrimary)

                                    Text(plant.scientificName)
                                        .font(.system(size: 14))
                                        .italic()
                                        .foregroundColor(.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.plantPrimary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.merlinBackground)
            .navigationTitle("My Scanned Plants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.plantPrimary)
                }
            }
        }
    }
}

// MARK: - Plant of the Day Hero BIG (55% of screen)

struct PlantOfTheDayHeroBig: View {
    let plant: Plant
    let onTap: () -> Void

    @State private var fetchedImageURL: String? = nil

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Plant Image Background - Fetches from API
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color(hex: plant.color).opacity(0.5),
                            Color(hex: plant.color).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Plant image from API or placeholder
                    if let urlString = fetchedImageURL ?? plant.imageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure(_), .empty:
                                plantPlaceholder
                            @unknown default:
                                plantPlaceholder
                            }
                        }
                    } else {
                        plantPlaceholder
                    }

                    // Decorative sparkle
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "sparkle")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(24)
                        }
                        Spacer()
                    }
                }
                .frame(height: 420)
                .onAppear { fetchImageIfNeeded() }

                // Bottom overlay with plant info
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR PLANT OF THE DAY")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.95))
                            .tracking(1.5)

                        Text(plant.commonName)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    ShareLink(item: "\(plant.commonName) (\(plant.scientificName)) — discovered with PlantAR!") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.85), Color.black.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 140)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var plantPlaceholder: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 180))
            .foregroundColor(Color(hex: plant.color).opacity(0.4))
            .offset(x: 60, y: -20)
    }

    private func fetchImageIfNeeded() {
        guard plant.imageURL == nil && fetchedImageURL == nil else { return }
        Task {
            do {
                // Use commonName for search (scientific names return premium-only images)
                let results = try await PlantAPIService.shared.searchPlants(query: plant.commonName)
                // Find first result with a valid image (not upgrade_access)
                if let validResult = results.first(where: { result in
                    if let imgURL = result.defaultImage?.mediumURL ?? result.defaultImage?.smallURL {
                        return !imgURL.contains("upgrade_access")
                    }
                    return false
                }),
                   let imgURL = validResult.defaultImage?.mediumURL ?? validResult.defaultImage?.regularURL ?? validResult.defaultImage?.smallURL ?? validResult.defaultImage?.originalURL {
                    await MainActor.run {
                        self.fetchedImageURL = imgURL
                    }
                }
            } catch {
                print("Failed to fetch image for \(plant.commonName): \(error)")
            }
        }
    }
}

// MARK: - Plant of the Day Hero (45% of screen) - LEGACY

struct PlantOfTheDayHero: View {
    let plant: Plant
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottom) {
                // Plant Image Background
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color(hex: plant.color).opacity(0.4),
                            Color(hex: plant.color).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Large plant visual
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 160))
                        .foregroundColor(Color(hex: plant.color).opacity(0.3))
                        .offset(x: 60, y: -30)

                    // Decorative sparkle
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "sparkle")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(24)
                        }
                        Spacer()
                    }
                }
                .frame(height: 340) // ~45% of screen

                // Bottom overlay with plant info
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR PLANT OF THE DAY")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(1)

                        Text(plant.commonName)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    ShareLink(item: "\(plant.commonName) (\(plant.scientificName)) — discovered with PlantAR!") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.4)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Action Circle Button (Merlin Style - Light gray bg, dark icons)

struct ActionCircleButton: View {
    let icon: String
    let label: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isPrimary ? Color.plantPrimary : Color(white: 0.91)) // Very light gray like Merlin
                        .frame(width: 80, height: 80)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(isPrimary ? .white : Color(white: 0.35)) // Dark gray icons like Merlin
                }

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPrimary ? Color.plantPrimary : .black) // Black text like Merlin
            }
        }
        .frame(width: 100)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step by Step View (Manual Input -> Suggestions)

struct StepByStepView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService

    @State private var currentStep = 1
    @State private var locationText = ""
    @State private var notes = ""
    @State private var dateSpotted = Date()
    @State private var flowerColor = ""
    @State private var leafShape = ""
    @State private var showingSuggestions = false

    var filteredSuggestions: [Plant] {
        var results = plantDatabase
        let color = flowerColor.lowercased().trimmingCharacters(in: .whitespaces)
        let leaf = leafShape.lowercased().trimmingCharacters(in: .whitespaces)
        if !color.isEmpty {
            results = results.filter { plant in
                plant.description.lowercased().contains(color) ||
                plant.funFacts.joined().lowercased().contains(color)
            }
        }
        if !leaf.isEmpty {
            results = results.filter { plant in
                plant.description.lowercased().contains(leaf) ||
                plant.plantParts.map { $0.function }.joined().lowercased().contains(leaf)
            }
        }
        return results.isEmpty ? plantDatabase : results
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.plantPrimary : Color.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                if !showingSuggestions {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Step indicator
                            Text("Step \(currentStep) of 3")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(white: 0.4))

                            if currentStep == 1 {
                                // Location & Date
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Where and when?")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Location")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.4))

                                        HStack {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.plantPrimary)
                                            TextField("", text: $locationText, prompt: Text("Where did you see it?").foregroundColor(.gray))
                                                .font(.system(size: 17))
                                                .foregroundColor(.black)
                                        }
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Date")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.4))

                                        DatePicker("", selection: $dateSpotted, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .labelsHidden()
                                            .padding(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                                .padding(.horizontal, 20)
                            } else if currentStep == 2 {
                                // Characteristics
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("What did it look like?")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Flower Color (if any)")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.4))

                                        TextField("", text: $flowerColor, prompt: Text("e.g., Red, Yellow, White").foregroundColor(.gray))
                                            .font(.system(size: 17))
                                            .foregroundColor(.black)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Leaf Shape")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.4))

                                        TextField("", text: $leafShape, prompt: Text("e.g., Round, Pointed, Oval").foregroundColor(.gray))
                                            .font(.system(size: 17))
                                            .foregroundColor(.black)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                                .padding(.horizontal, 20)
                            } else if currentStep == 3 {
                                // Notes
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Any other details?")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Notes (optional)")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(white: 0.4))

                                        TextField("", text: $notes, prompt: Text("Add any other observations...").foregroundColor(.gray), axis: .vertical)
                                            .font(.system(size: 17))
                                            .foregroundColor(.black)
                                            .lineLimit(4...8)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 8)
                    }

                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentStep > 1 {
                            Button(action: { currentStep -= 1 }) {
                                Text("Back")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.plantPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.plantPrimary, lineWidth: 2))
                            }
                        }

                        Button(action: {
                            if currentStep < 3 {
                                currentStep += 1
                            } else {
                                showingSuggestions = true
                            }
                        }) {
                            Text(currentStep == 3 ? "Find Plants" : "Next")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.plantPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                } else {
                    // Show plant suggestions
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Possible Matches")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)

                                Text("Based on your description, these plants might match")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.4))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            // Plant suggestions filtered by user inputs
                            LazyVStack(spacing: 0) {
                                ForEach(filteredSuggestions) { plant in
                                    PhotoSuggestionRow(plant: plant)
                                        .environmentObject(persistence)
                                        .environmentObject(auth)
                                    Divider().padding(.leading, 100)
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .background(Color(red: 0.97, green: 0.97, blue: 0.96))
            .navigationTitle("Step by Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.plantPrimary)
                }
            }
        }
    }
}

// MARK: - Plant Selection Card

struct PlantSelectionCard: View {
    let plant: Plant
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: plant.color).opacity(0.15))
                        .frame(height: 80)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: plant.color))
                }

                Text(plant.commonName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.plantPrimary : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Photo Identify View (Opens Photo Picker)

struct PhotoIdentifyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showingSuggestions = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let image = selectedImage {
                    // Show selected image and suggestions
                    ScrollView {
                        VStack(spacing: 24) {
                            // Selected photo
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280)
                                .clipped()

                            // Suggestions header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Possible Matches")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.textPrimary)

                                Text("Select the plant that matches your photo")
                                    .font(.system(size: 15))
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                            // Plant suggestions
                            LazyVStack(spacing: 0) {
                                ForEach(plantDatabase) { plant in
                                    PhotoSuggestionRow(plant: plant)
                                        .environmentObject(persistence)
                                        .environmentObject(auth)
                                    Divider().padding(.leading, 100)
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                } else {
                    // Photo picker prompt
                    VStack(spacing: 32) {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 64))
                                .foregroundColor(.gray)

                            Text("Select a Photo")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)

                            Text("Choose a photo of a plant from your library to identify it")
                                .font(.system(size: 17))
                                .foregroundColor(.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 18))
                                Text("Choose from Library")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.plantPrimary)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .background(Color.merlinBackground)
            .navigationTitle("Photo ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.plantPrimary)
                }
                if selectedImage != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Change")
                                .foregroundColor(.plantPrimary)
                        }
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
        }
    }
}

// MARK: - Photo Suggestion Row

struct PhotoSuggestionRow: View {
    let plant: Plant
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService
    @State private var showDetail = false

    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(spacing: 16) {
                // Plant thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: plant.color).opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: plant.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.commonName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)

                    Text(plant.scientificName)
                        .font(.system(size: 15))
                        .italic()
                        .foregroundColor(Color(white: 0.3))

                    // Rarity badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: plant.rarity.color))
                            .frame(width: 8, height: 8)
                        Text(plant.rarity.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: plant.rarity.color))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            PlantDetailView(plant: plant)
                .environmentObject(persistence)
                .environmentObject(auth)
        }
    }
}

// MARK: - Photo Plant Card

struct PhotoPlantCard: View {
    let plant: Plant
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image
                ZStack {
                    Rectangle()
                        .fill(Color(hex: plant.color).opacity(0.2))

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: plant.color))
                }
                .frame(height: 120)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.commonName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text(plant.scientificName)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(.textSecondary)

                    // Rarity badge
                    Text(plant.rarity.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: plant.rarity.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: plant.rarity.color).opacity(0.15))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.cardBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Plant Info with AR Request

struct PlantInfoWithARRequest: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService

    let plant: Plant
    @State private var showARView = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Plant Header Image
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: plant.color).opacity(0.2))

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: plant.color))
                    }
                    .frame(height: 280)

                    // Plant Info - WHITE background like Merlin
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plant.commonName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)

                            Text(plant.scientificName)
                                .font(.system(size: 18))
                                .italic()
                                .foregroundColor(Color(white: 0.4))
                        }
                        .padding(.top, 20)

                        // Rarity and Bloom badges
                        HStack(spacing: 12) {
                            Label(plant.rarity.rawValue, systemImage: "sparkles")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: plant.rarity.color))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: plant.rarity.color).opacity(0.15))
                                .cornerRadius(8)

                            Label("Blooms Spring-Fall", systemImage: "sun.max.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(8)
                        }

                        Text(plant.description)
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.3))
                            .lineSpacing(5)

                        // Fun Facts
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fun Facts")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)

                            ForEach(plant.funFacts, id: \.self) { fact in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "sparkle")
                                        .foregroundColor(.plantPrimary)
                                    Text(fact)
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(white: 0.3))
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 24)

                    // AR Button
                    if plant.hasARModel {
                        Button(action: { showARView = true }) {
                            HStack {
                                Image(systemName: "arkit")
                                Text("View in AR")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.plantPrimary)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Add to Garden button
                    Button(action: addToGarden) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to My Garden")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.plantPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(white: 0.12))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.plantPrimary, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.white) // WHITE background like Merlin
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(white: 0.7))
                    }
                }
            }
            .fullScreenCover(isPresented: $showARView) {
                ARScanView()
                    .environmentObject(persistence)
                    .environmentObject(auth)
            }
        }
    }

    private func addToGarden() {
        guard let studentID = auth.currentStudentID else { return }
        persistence.addToGarden(plantID: plant.id, studentID: studentID)
        dismiss()
    }
}

// MARK: - Explore Tab (Merlin-Style List)

struct ExploreTab: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var persistence: PersistenceService
    @State private var searchText = ""
    @AppStorage("showScientificNames") private var showScientificNames = false

    var filteredPlants: [Plant] {
        let sorted = plantDatabase.sorted { $0.commonName < $1.commonName }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.commonName.localizedCaseInsensitiveContains(searchText) ||
            $0.scientificName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Explore Plants")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)

                Text("\(plantDatabase.count) common USA plants")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)

                TextField("Search", text: $searchText)
                    .font(.system(size: 18))
                    .foregroundColor(.black)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 0.94, green: 0.95, blue: 0.93))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Plant List
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(filteredPlants) { plant in
                        PlantListRow(plant: plant)
                            .environmentObject(persistence)
                            .environmentObject(auth)
                        Divider()
                            .padding(.leading, 108)
                    }
                }
            }
        }
        .background(Color.white)
    }
}

// MARK: - Plant List Row (Merlin-style)

struct PlantListRow: View {
    let plant: Plant
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService
    @State private var showDetail = false
    @AppStorage("showScientificNames") private var showScientificNames = false

    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(spacing: 16) {
                // Plant thumbnail - Real image from API
                PlantImageView(plant: plant, size: 88, cornerRadius: 8)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Plant info
                VStack(alignment: .leading, spacing: 6) {
                    Text(showScientificNames ? plant.scientificName : plant.commonName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .italic(showScientificNames)

                    // Bloom season bar - directly inline
                    BloomSeasonBar(bloomMonths: plant.bloomMonths)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            PlantDetailView(plant: plant)
                .environmentObject(persistence)
                .environmentObject(auth)
        }
    }
}

// MARK: - Bloom Season Bar (Merlin-style with clear visibility)

struct BloomSeasonBar: View {
    let bloomMonths: [Int]
    let months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Season bars - each month gets multiple small bars for density effect
            HStack(spacing: 1) {
                ForEach(1...12, id: \.self) { month in
                    // Each month has 3 small vertical bars
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .fill(bloomMonths.contains(month) ? Color.plantPrimary : Color.gray.opacity(0.25))
                                .frame(width: 4, height: bloomMonths.contains(month) ? 14 : 8)
                        }
                    }
                }
            }

            // Month labels - spaced to align with bars
            HStack(spacing: 0) {
                ForEach(0..<12, id: \.self) { index in
                    Text(months[index])
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 15)
                }
            }
        }
    }
}

// MARK: - Plant Detail View (Merlin-style with "This is my plant" button)

struct PlantDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService
    let plant: Plant
    @State private var showARView = false
    @State private var fetchedImageURL: String? = nil
    @State private var isLoadingImage = false

    // Hardiness/Range map data from API
    @State private var hardinessMapURL: String? = nil
    @State private var hardinessMin: String? = nil
    @State private var hardinessMax: String? = nil
    @State private var isLoadingHardiness = false

    // Convert bloom months to readable text
    var bloomMonthsText: String {
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        if plant.bloomMonths.count == 12 {
            return "Year-round"
        } else if plant.bloomMonths.isEmpty {
            return "N/A"
        } else {
            let firstMonth = monthNames[plant.bloomMonths.first! - 1]
            let lastMonth = monthNames[plant.bloomMonths.last! - 1]
            return "\(firstMonth) - \(lastMonth)"
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero image area
                        ZStack(alignment: .topLeading) {
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: plant.color).opacity(0.3), Color(hex: plant.color).opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )

                                // Real plant image from API
                                if let urlString = fetchedImageURL ?? plant.imageURL,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .failure(_):
                                            Image(systemName: "leaf.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(Color(hex: plant.color).opacity(0.5))
                                        case .empty:
                                            ProgressView()
                                                .scaleEffect(1.5)
                                                .tint(Color(hex: plant.color))
                                        @unknown default:
                                            Image(systemName: "leaf.fill")
                                                .font(.system(size: 100))
                                                .foregroundColor(Color(hex: plant.color).opacity(0.5))
                                        }
                                    }
                                } else if isLoadingImage {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(Color(hex: plant.color))
                                } else {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(Color(hex: plant.color).opacity(0.5))
                                }
                            }
                            .frame(height: 320)
                            .clipped()
                            .onAppear { fetchPlantImage() }

                            // Back button
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            .padding(.leading, 16)
                            .padding(.top, 16)

                            // Image counter — only shown when an image is available
                            if (fetchedImageURL ?? plant.imageURL) != nil {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Text("1 of 1")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.black.opacity(0.6))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                                .frame(height: 320)
                            }
                        }

                        // Content
                        VStack(alignment: .leading, spacing: 20) {
                            // Title row
                            HStack {
                                Text(plant.commonName)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)

                                Spacer()

                                ShareLink(item: "\(plant.commonName) (\(plant.scientificName)) — discovered with PlantAR!") {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                }
                            }

                            // Rarity badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: plant.rarity.color))
                                    .frame(width: 10, height: 10)
                                Text(plant.rarity.rawValue)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: plant.rarity.color))
                            }

                            // Scientific name
                            Text(plant.scientificName)
                                .font(.system(size: 17))
                                .italic()
                                .foregroundColor(.gray)

                            // Description
                            Text(plant.description)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.black.opacity(0.85))
                                .lineSpacing(4)

                            // Range / Native Region section (like Merlin's range maps)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Range")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)

                                // Availability badges
                                HStack(spacing: 12) {
                                    // Availability badge
                                    HStack(spacing: 6) {
                                        Rectangle()
                                            .fill(plant.availability == .yearRound ? Color.purple.opacity(0.7) : Color.orange.opacity(0.7))
                                            .frame(width: 12, height: 12)
                                            .cornerRadius(2)
                                        Text(plant.availability.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.black.opacity(0.7))
                                    }

                                    // Bloom season
                                    HStack(spacing: 6) {
                                        Rectangle()
                                            .fill(Color.plantPrimary.opacity(0.7))
                                            .frame(width: 12, height: 12)
                                            .cornerRadius(2)
                                        Text("Blooms: \(bloomMonthsText)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.black.opacity(0.7))
                                    }
                                }

                                // Native region with icon
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "globe.americas.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.plantPrimary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Native Region")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                        Text(plant.nativeRegion)
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(12)
                            }
                            .padding(.top, 12)

                            // Fun Facts section
                            if !plant.funFacts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Fun Facts")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.black)

                                    ForEach(plant.funFacts, id: \.self) { fact in
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: "leaf.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.plantPrimary)
                                                .frame(width: 20)

                                            Text(fact)
                                                .font(.system(size: 16))
                                                .foregroundColor(.black.opacity(0.8))
                                        }
                                    }
                                }
                                .padding(.top, 16)
                            }

                            // Range / Hardiness Zone Map Section (like Merlin's range maps)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Range")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)

                                if isLoadingHardiness {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Spacer()
                                    }
                                    .frame(height: 200)
                                } else if let mapURL = hardinessMapURL {
                                    // Hardiness map from API (WebView because it returns HTML)
                                    HardinessMapWebView(urlString: mapURL)
                                        .frame(height: 350)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )

                                    // Map Legend - Blooming Seasons
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("When to Find This Plant")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)

                                        // Blooming Season Visual
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Blooming Season")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)

                                            // Month bar showing when plant blooms
                                            HStack(spacing: 2) {
                                                ForEach(1...12, id: \.self) { month in
                                                    Rectangle()
                                                        .fill(plant.bloomMonths.contains(month) ? Color.plantPrimary : Color.gray.opacity(0.2))
                                                        .frame(height: 24)
                                                        .overlay(
                                                            Text(monthAbbrev(month))
                                                                .font(.system(size: 8, weight: .medium))
                                                                .foregroundColor(plant.bloomMonths.contains(month) ? .white : .gray)
                                                        )
                                                }
                                            }
                                            .cornerRadius(6)
                                        }

                                        // Availability badge
                                        HStack(spacing: 8) {
                                            Image(systemName: bloomingIcon)
                                                .font(.system(size: 16))
                                                .foregroundColor(.plantPrimary)
                                            Text(bloomingDescription)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.black)
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.plantPrimary.opacity(0.1))
                                        .cornerRadius(8)

                                        // Map explanation
                                        Text("Map shows regions in the US where this plant can grow based on climate conditions.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.top, 12)
                                } else {
                                    // Fallback when no map available - show native region info
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "globe.americas.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.plantPrimary)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Native Region")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.black)
                                                Text(plant.nativeRegion)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.black.opacity(0.7))
                                            }
                                        }

                                        HStack(spacing: 12) {
                                            Image(systemName: "calendar")
                                                .font(.system(size: 24))
                                                .foregroundColor(.plantPrimary)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Availability")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.black)
                                                Text(plant.availability.rawValue)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.black.opacity(0.7))
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.08))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.top, 24)

                            // AR View button
                            if plant.hasARModel {
                                Button(action: { showARView = true }) {
                                    HStack {
                                        Image(systemName: "arkit")
                                        Text("View in AR")
                                    }
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.plantPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                                }
                                .padding(.top, 12)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }

                // Fixed bottom button
                VStack(spacing: 0) {
                    Divider()
                    Button(action: addToGarden) {
                        Text("This is my plant")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.plantPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showARView) {
                ARScanView()
                    .environmentObject(persistence)
                    .environmentObject(auth)
            }
        }
    }

    // Placeholder for when map fails to load
    private var rangeMapPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("Map not available")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // USDA Hardiness Zone color mapping (zones 1-13)
    private func hardinessZoneColor(zone: Int) -> Color {
        switch zone {
        case 1: return Color(red: 0.6, green: 0.4, blue: 0.8)   // Purple - coldest
        case 2: return Color(red: 0.4, green: 0.5, blue: 0.9)   // Blue-purple
        case 3: return Color(red: 0.2, green: 0.6, blue: 0.9)   // Blue
        case 4: return Color(red: 0.2, green: 0.7, blue: 0.8)   // Cyan-blue
        case 5: return Color(red: 0.2, green: 0.75, blue: 0.6)  // Teal
        case 6: return Color(red: 0.3, green: 0.8, blue: 0.4)   // Green
        case 7: return Color(red: 0.5, green: 0.85, blue: 0.3)  // Light green
        case 8: return Color(red: 0.7, green: 0.85, blue: 0.2)  // Yellow-green
        case 9: return Color(red: 0.9, green: 0.85, blue: 0.2)  // Yellow
        case 10: return Color(red: 0.95, green: 0.7, blue: 0.2) // Orange-yellow
        case 11: return Color(red: 0.95, green: 0.5, blue: 0.2) // Orange
        case 12: return Color(red: 0.9, green: 0.3, blue: 0.2)  // Red-orange
        case 13: return Color(red: 0.85, green: 0.2, blue: 0.2) // Red - hottest
        default: return Color.gray
        }
    }

    // Month abbreviation helper
    private func monthAbbrev(_ month: Int) -> String {
        let abbrevs = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        return abbrevs[month - 1]
    }

    // Blooming season description
    private var bloomingDescription: String {
        let months = plant.bloomMonths
        if months.count == 12 {
            return "Blooms year-round"
        } else if months.count >= 9 {
            return "Blooms most of the year"
        } else if Set(months) == Set([3, 4, 5]) || Set(months).isSubset(of: Set([3, 4, 5])) {
            return "Spring bloomer"
        } else if Set(months).isSubset(of: Set([6, 7, 8])) {
            return "Summer bloomer"
        } else if Set(months).isSubset(of: Set([9, 10, 11])) {
            return "Fall bloomer"
        } else if Set(months).isSubset(of: Set([12, 1, 2])) {
            return "Winter bloomer"
        } else if months.contains(where: { [3,4,5].contains($0) }) && months.contains(where: { [6,7,8].contains($0) }) {
            return "Spring to summer bloomer"
        } else if months.contains(where: { [6,7,8].contains($0) }) && months.contains(where: { [9,10,11].contains($0) }) {
            return "Summer to fall bloomer"
        } else {
            return "Seasonal bloomer"
        }
    }

    // Blooming icon
    private var bloomingIcon: String {
        let months = plant.bloomMonths
        if months.count == 12 {
            return "calendar.circle.fill"
        } else if months.contains(where: { [6, 7, 8].contains($0) }) {
            return "sun.max.fill"
        } else if months.contains(where: { [12, 1, 2].contains($0) }) {
            return "snowflake"
        } else if months.contains(where: { [3, 4, 5].contains($0) }) {
            return "leaf.fill"
        } else {
            return "calendar"
        }
    }

    private func addToGarden() {
        guard let studentID = auth.currentStudentID else { return }
        persistence.addToGarden(plantID: plant.id, studentID: studentID)
        dismiss()
    }

    private func fetchPlantImage() {
        guard plant.imageURL == nil && fetchedImageURL == nil else { return }
        isLoadingImage = true
        isLoadingHardiness = true

        Task {
            do {
                // Use commonName for search (scientific names return premium-only images)
                let results = try await PlantAPIService.shared.searchPlants(query: plant.commonName)

                // Find first result with a valid image (not upgrade_access)
                if let validResult = results.first(where: { result in
                    if let imgURL = result.defaultImage?.mediumURL ?? result.defaultImage?.smallURL {
                        return !imgURL.contains("upgrade_access")
                    }
                    return false
                }) {
                    // Set the image URL
                    let imgURL = validResult.defaultImage?.mediumURL ?? validResult.defaultImage?.regularURL ?? validResult.defaultImage?.smallURL
                    await MainActor.run {
                        self.fetchedImageURL = imgURL
                        self.isLoadingImage = false
                    }

                    // Now fetch the detailed info to get the hardiness map
                    let details = try await PlantAPIService.shared.getPlantDetails(id: validResult.id)
                    await MainActor.run {
                        self.hardinessMapURL = details.hardinessLocation?.fullURL
                        self.hardinessMin = details.hardiness?.min
                        self.hardinessMax = details.hardiness?.max
                        self.isLoadingHardiness = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingImage = false
                        self.isLoadingHardiness = false
                    }
                }
            } catch {
                print("Failed to fetch plant data: \(error)")
                await MainActor.run {
                    self.isLoadingImage = false
                    self.isLoadingHardiness = false
                }
            }
        }
    }
}

// MARK: - Garden Tab (Life List Style)

struct GardenTab: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var persistence: PersistenceService
    @State private var selectedPlant: Plant? = nil
    @StateObject private var locationManager = LocationManager()

    var isSignedIn: Bool {
        auth.currentStudentID != nil && !auth.currentStudentID!.isEmpty
    }

    var studentGarden: [GardenRecord] {
        persistence.myGarden.filter { $0.studentID == auth.currentStudentID }
    }

    var discoveredPlantIDs: Set<String> {
        Set(studentGarden.map { $0.plantID })
    }

    var suggestedPlants: [Plant] {
        // Return plants not yet discovered (up to 10)
        plantDatabase.filter { !discoveredPlantIDs.contains($0.id) }.prefix(10).map { $0 }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Garden")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)

                    if !isSignedIn {
                        Text("Sign in to view your garden")
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.45))
                    } else if studentGarden.isEmpty {
                        Text("Add your first plant!")
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.45))
                    } else {
                        Text("\(studentGarden.count) plants discovered")
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.45))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)

                Divider()
                    .padding(.horizontal, 20)

                // Show sign-in prompt if not signed in
                if !isSignedIn {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)

                        Image(systemName: "leaf.circle")
                            .font(.system(size: 64))
                            .foregroundColor(Color(white: 0.7))

                        Text("Sign In Required")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Sign in to start building your plant collection and track your discoveries.")
                            .font(.system(size: 16))
                            .foregroundColor(Color(white: 0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                } else {
                    // Your Collection (List View - on top)
                    if !studentGarden.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height: 24)

                            Text("Your Collection")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                            // List View (like Explore tab)
                            LazyVStack(spacing: 0) {
                                ForEach(plantDatabase.filter { discoveredPlantIDs.contains($0.id) }) { plant in
                                    PlantListRow(plant: plant)
                                        .environmentObject(persistence)
                                        .environmentObject(auth)
                                    Divider()
                                        .padding(.leading, 108)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }

                    // Suggested Plants Section (on bottom)
                    if !suggestedPlants.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            if studentGarden.isEmpty {
                                Spacer().frame(height: 24)
                            }

                            HStack {
                                Text("Can you find these plants nearby?")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.black)

                                Spacer()

                                Image(systemName: "location.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.plantPrimary)
                            }
                            .padding(.horizontal, 20)

                            Text("Likely today for \(locationManager.cityName)")
                                .font(.system(size: 15))
                                .foregroundColor(Color(white: 0.45))
                                .padding(.horizontal, 20)

                            // Plant Grid
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 14
                            ) {
                                ForEach(suggestedPlants) { plant in
                                    GardenPlantCard(
                                        plant: plant,
                                        isDiscovered: discoveredPlantIDs.contains(plant.id)
                                    ) {
                                        selectedPlant = plant
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .background(Color.merlinBackground)
        .onAppear { locationManager.requestLocation() }
        .sheet(item: $selectedPlant) { plant in
            PlantInfoWithARRequest(plant: plant)
                .environmentObject(persistence)
                .environmentObject(auth)
        }
    }
}

// MARK: - Garden Plant Card (Merlin Style - Real images, white info area)

struct GardenPlantCard: View {
    let plant: Plant
    let isDiscovered: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image area - Uses API images
                ZStack {
                    PlantImageView(plant: plant, size: 140)

                    // Checkmark for discovered
                    if isDiscovered {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.plantPrimary)
                                    .background(Circle().fill(Color.white).padding(2))
                                    .padding(10)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 140)

                // Info area - WHITE background with BLACK text (like Merlin)
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.commonName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(plant.scientificName)
                        .font(.system(size: 14))
                        .italic()
                        .foregroundColor(Color(white: 0.45))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .opacity(isDiscovered ? 1.0 : 0.7)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Tab

struct SettingsTab: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var persistence: PersistenceService
    @AppStorage("showScientificNames") private var showScientificNames = false
    @AppStorage("dailyReminder") private var dailyReminder = false
    @State private var showAbout = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                Text("Settings")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                // User Card (Sign In style like Merlin) - WHITE card
                SettingsCard {
                    HStack(spacing: 16) {
                        // App icon placeholder
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.plantPrimary)
                            .frame(width: 52, height: 52)
                            .background(Color.plantPrimary.opacity(0.12))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(auth.currentStudentName ?? "Sign In")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            if auth.currentStudentID != nil {
                                Text("Class: \(auth.classCode)")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.5))
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // My Offline Plants (like Merlin's "My offline birds")
                SettingsSection(title: nil) {
                    MerlinSettingsRow(
                        title: "My offline plants",
                        subtitle: "Download before you go!",
                        showChevron: true
                    )
                }

                // Display Settings
                SettingsSection(title: "COMMON NAME LANGUAGE") {
                    SettingsToggleRow(
                        title: "Show Scientific Names",
                        isOn: $showScientificNames
                    )
                }

                // Plant of the Day
                SettingsSection(title: "PLANT OF THE DAY") {
                    SettingsToggleRow(
                        title: "Send me a daily reminder",
                        isOn: $dailyReminder
                    )
                }

                // Plants
                SettingsSection(title: "PLANTS") {
                    HStack {
                        Text("Supported Plants")
                            .font(.system(size: 17))
                            .foregroundColor(.black)
                        Spacer()
                        Text("\(plantDatabase.count) plants")
                            .font(.system(size: 17))
                            .foregroundColor(.plantPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }

                // Support
                SettingsSection(title: "SUPPORT") {
                    MerlinSettingsRow(title: "Help", showChevron: true)
                    Divider().padding(.leading, 20)
                    Button(action: { showAbout = true }) {
                        MerlinSettingsRow(title: "About PlantAR", showChevron: true)
                    }
                    Divider().padding(.leading, 20)
                    MerlinSettingsRow(title: "Tell a Friend", showChevron: true)
                    Divider().padding(.leading, 20)
                    Button(action: {
                        if let url = URL(string: "mailto:support@plantar.app?subject=PlantAR%20Feedback") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        MerlinSettingsRow(title: "Send Us Feedback", showChevron: true)
                    }
                }
                .sheet(isPresented: $showAbout) {
                    VStack(spacing: 20) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.plantPrimary)
                            .padding(.top, 40)
                        Text("PlantAR")
                            .font(.system(size: 28, weight: .bold))
                        Text("Version 1.0 (2026)")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        Text("PlantAR is an augmented reality plant education app designed for students to explore and learn about plants in an interactive way.\n\nPoint your camera at a PlantAR card to bring plants to life in 3D — then tap parts of the model to discover their functions.")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Spacer()
                        Button("Close") { showAbout = false }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.plantPrimary)
                            .padding(.bottom, 40)
                    }
                    .presentationDetents([.medium])
                }

                // Legal
                SettingsSection(title: nil) {
                    MerlinSettingsRow(title: "Privacy Policy", showChevron: true)
                    Divider().padding(.leading, 20)
                    MerlinSettingsRow(title: "Terms of Use", showChevron: true)
                }

                // App Version
                SettingsSection(title: "APP VERSION") {
                    Text("1.0 (2026)")
                        .font(.system(size: 16))
                        .foregroundColor(Color(white: 0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                }

                // Sign Out
                Button(action: { auth.logout() }) {
                    Text("Sign Out")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.botanicalError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
        .background(Color.merlinBackground)
        .onChange(of: dailyReminder) { enabled in
            if enabled {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    guard granted else {
                        DispatchQueue.main.async { dailyReminder = false }
                        return
                    }
                    let content = UNMutableNotificationContent()
                    content.title = "PlantAR"
                    content.body = "Explore today's Plant of the Day and grow your garden!"
                    content.sound = .default
                    var components = DateComponents()
                    components.hour = 9
                    components.minute = 0
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    let request = UNNotificationRequest(
                        identifier: "plantAR.dailyReminder",
                        content: content,
                        trigger: trigger
                    )
                    UNUserNotificationCenter.current().add(request)
                }
            } else {
                UNUserNotificationCenter.current().removePendingNotificationRequests(
                    withIdentifiers: ["plantAR.dailyReminder"]
                )
            }
        }
    }
}

// MARK: - Settings Components (Merlin Style - White cards, black text)

struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(Color.white) // WHITE like Merlin
            .cornerRadius(12)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(white: 0.5)) // Gray section header like Merlin
                    .padding(.horizontal, 20)
            }

            VStack(spacing: 0) {
                content
            }
            .background(Color.white) // WHITE like Merlin
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 28)
    }
}

struct MerlinSettingsRow: View {
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.black) // BLACK text like Merlin

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(Color(white: 0.5)) // Gray subtitle
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(white: 0.7)) // Light gray chevron
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.black) // BLACK text like Merlin

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.plantPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - AR Scan View

struct ARScanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService

    @StateObject private var arManager = OptimizedARManager()
    @State private var detectedPlant: Plant? = nil
    @State private var showPlantInfo = false

    var body: some View {
        ZStack {
            ARViewContainer(
                arManager: arManager,
                detectedPlant: $detectedPlant
            )
            .ignoresSafeArea()

            VStack {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    if let plant = detectedPlant {
                        HStack(spacing: 10) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 16))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plant.commonName)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(plant.scientificName)
                                    .font(.system(size: 12))
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(24)

                        Spacer()

                        Button(action: { showPlantInfo = true }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Bottom Guidance
                if !arManager.modelLoaded {
                    VStack(spacing: 14) {
                        if detectedPlant != nil {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Loading 3D model...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "viewfinder")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Text("Point camera at any plant card")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(28)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 100)
                } else {
                    if arManager.tappedPart == nil {
                        HStack(spacing: 20) {
                            HintBadge(icon: "hand.pinch", text: "Zoom")
                            HintBadge(icon: "hand.draw", text: "Rotate")
                            HintBadge(icon: "hand.tap", text: "Tap parts")
                        }
                        .padding(.bottom, 100)
                        .transition(.opacity)
                    }
                }
            }

            // Part tap popup — slides up from bottom when student taps a named mesh
            if let part = arManager.tappedPart {
                VStack {
                    Spacer()
                    PartPopupOverlay(part: part) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            arManager.tappedPart = nil
                            if let name = part.modelPartName { arManager.unhighlightPart(named: name) }
                        }
                    } onSeeAll: {
                        arManager.tappedPart = nil
                        showPlantInfo = true
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: arManager.tappedPart != nil)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: arManager.tappedPart != nil)
        .onChange(of: arManager.modelLoaded) { _, loaded in
            if loaded, detectedPlant != nil {
                showPlantInfo = true
            }
        }
        .sheet(isPresented: $showPlantInfo) {
            if let plant = detectedPlant {
                MerlinStylePlantInfoSheet(plant: plant, arManager: arManager)
                    .environmentObject(persistence)
                    .environmentObject(auth)
                    .presentationDetents([.medium, .large])
            }
        }
        .overlay(alignment: .bottom) {
            if let errorMessage = arManager.error {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                    .transition(.opacity)
            }
        }
        .statusBarHidden(true)
    }
}

struct HintBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.4))
        .cornerRadius(24)
    }
}

// MARK: - Part Tap Popup

struct PartPopupOverlay: View {
    let part: PlantPart
    let onDismiss: () -> Void
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pull handle
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.gray.opacity(0.35))
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 18)

            // Name + dismiss
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(part.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Text(part.scientificName)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(.systemGray3))
                }
            }
            .padding(.horizontal, 20)

            // Function description
            Text(part.function)
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.65))
                .lineSpacing(3)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            // Link to full anatomy sheet
            Button(action: onSeeAll) {
                HStack(spacing: 4) {
                    Text("View all plant anatomy")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.plantPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -6)
        )
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    var arManager: OptimizedARManager
    @Binding var detectedPlant: Plant?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARImageTrackingConfiguration()
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "PlantCards", bundle: nil) {
            config.trackingImages = referenceImages
            config.maximumNumberOfTrackedImages = 4
            print("[AR] Loaded \(referenceImages.count) reference images")
        } else {
            print("[AR] ERROR: Could not load PlantCards reference images")
        }

        arManager.arView = arView
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        context.coordinator.detectedPlantBinding = $detectedPlant

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        // Tap only fires when pinch and pan are not active
        tap.require(toFail: pinch)
        arView.addGestureRecognizer(pinch)
        arView.addGestureRecognizer(pan)
        arView.addGestureRecognizer(tap)

        arView.session.run(config)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(arManager: arManager)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        let arManager: OptimizedARManager
        var arView: ARView?
        var detectedPlantBinding: Binding<Plant?>?
        var currentPlant: Plant?
        var loadedAnchors: Set<UUID> = []

        init(arManager: OptimizedARManager) {
            self.arManager = arManager
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor,
                      let arView = arView,
                      let detectedImageName = imageAnchor.referenceImage.name,
                      !loadedAnchors.contains(anchor.identifier) else { continue }

                if let plant = plantDatabase.first(where: { $0.arImageReferenceName == detectedImageName }) {
                    print("[AR] Detected plant: \(plant.commonName) from image: \(detectedImageName)")
                    loadedAnchors.insert(anchor.identifier)
                    currentPlant = plant
                    DispatchQueue.main.async {
                        self.detectedPlantBinding?.wrappedValue = plant
                    }
                    arManager.removePlant()
                    arManager.loadPlantModelAsync(plant, on: imageAnchor, in: arView)
                } else {
                    print("[AR] Unknown image detected: \(detectedImageName)")
                }
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor,
                      let arView = arView,
                      let detectedImageName = imageAnchor.referenceImage.name,
                      !loadedAnchors.contains(anchor.identifier) else { continue }

                if let plant = plantDatabase.first(where: { $0.arImageReferenceName == detectedImageName }) {
                    loadedAnchors.insert(anchor.identifier)
                    currentPlant = plant
                    DispatchQueue.main.async {
                        self.detectedPlantBinding?.wrappedValue = plant
                    }
                    arManager.removePlant()
                    arManager.loadPlantModelAsync(plant, on: imageAnchor, in: arView)
                }
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView,
                  let plant = currentPlant,
                  gesture.state == .ended,
                  arManager.modelLoaded else { return }
            let location = gesture.location(in: arView)
            arManager.handleTap(at: location, in: arView, for: plant)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let plant = currentPlant, gesture.state == .changed else { return }
            arManager.applyZoom(Float(gesture.scale), plant: plant)
            gesture.scale = 1.0
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView, gesture.state == .changed else { return }
            let translation = gesture.translation(in: arView)
            arManager.applyRotation(Float(translation.x) * 0.01)
            gesture.setTranslation(.zero, in: arView)
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let merlinBackground = Color(red: 0.96, green: 0.97, blue: 0.95)
    static let searchBarBackground = Color(red: 0.91, green: 0.93, blue: 0.89)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
        .environmentObject(PersistenceService.shared)
}
