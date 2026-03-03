import SwiftUI

/// The high-fidelity educational interface, now fully integrated with
/// Student Auth and Garden Persistence services.
struct MerlinStylePlantInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Integrated Services
    @EnvironmentObject var persistence: PersistenceService
    @EnvironmentObject var auth: AuthService
    
    let plant: Plant
    var arManager: OptimizedARManager? = nil

    // MARK: - State Management
    @State private var selectedTab: InfoTab = .overview
    @State private var highlightedPartID: String? = nil
    @State private var timeSpent: Int = 0
    @State private var isTimeTracking = false
    @State private var showQuizFullScreen = false

    // Hardiness / sunlight fetched from API
    @State private var hardinessZone: String? = nil
    @State private var sunlight: String? = nil
    
    enum InfoTab: String, CaseIterable {
        case overview = "About"
        case parts = "Anatomy"
        case roots = "Roots"
        case facts = "Facts"
        case quiz = "Quiz"

        var icon: String {
            switch self {
            case .overview: return "book.fill"
            case .parts: return "leaf.fill"
            case .roots: return "shared.with.you"
            case .facts: return "lightbulb.fill"
            case .quiz: return "questionmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator & Header
            HeaderView(plant: plant, dismiss: { dismiss() })
            
            // Custom Segmented Picker
            TabSelector(selectedTab: $selectedTab)
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .overview: overviewSection
                    case .parts: anatomySection
                    case .roots: rootSection
                    case .facts: factsSection
                    case .quiz: quizSection
                    }
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // Sticky Footer with Engagement Stats
            footerView
        }
        .onAppear {
            startSession()
            fetchGrowthInfo()
        }
        .onDisappear { endSession() }
        .fullScreenCover(isPresented: $showQuizFullScreen) {
            QuizView(plant: plant) { score in
                // Update persistence with quiz score
                if let studentID = auth.currentStudentID {
                    persistence.updateProgress(
                        plantID: plant.id,
                        studentID: studentID,
                        score: score,
                        timeSpent: 0
                    )
                }
            }
        }
    }
    
    // MARK: - Integrated Session Logic
    
    private func startSession() {
        isTimeTracking = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if isTimeTracking {
                timeSpent += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func endSession() {
        isTimeTracking = false
        guard let studentID = auth.currentStudentID else { return }

        persistence.addToGarden(plantID: plant.id, studentID: studentID)
        persistence.addTimeSpent(plantID: plant.id, studentID: studentID, timeSpent: timeSpent)
    }

    private func fetchGrowthInfo() {
        Task {
            do {
                let results = try await PlantAPIService.shared.searchPlants(query: plant.commonName)
                if let first = results.first {
                    let details = try await PlantAPIService.shared.getPlantDetails(id: first.id)
                    await MainActor.run {
                        if let min = details.hardiness?.min, let max = details.hardiness?.max {
                            hardinessZone = "Zone \(min)–\(max)"
                        }
                        if let sunArr = details.sunlight, let first = sunArr.first {
                            sunlight = first.replacingOccurrences(of: "_", with: " ").capitalized
                        }
                    }
                }
            } catch {
                // Silently fall back to "—" display
            }
        }
    }
    
    // MARK: - Sub-Sections
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BotanicalCard(title: "Summary", content: plant.description)
            
            HStack(spacing: 12) {
                StatPill(icon: "🌡️", label: "Hardiness", value: hardinessZone ?? "—")
                StatPill(icon: "☀️", label: "Light", value: sunlight ?? "—")
            }
        }
    }
    
    private var anatomySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tap an anatomical part to learn its function:")
                .font(.subheadline).foregroundColor(.secondary)
            
            ForEach(plant.plantParts) { part in
                PartCard(part: part, isHighlighted: highlightedPartID == part.id) {
                    let isDeselecting = highlightedPartID == part.id
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        highlightedPartID = isDeselecting ? nil : part.id
                    }
                    if isDeselecting {
                        arManager?.unhighlightPart(named: part.modelPartName ?? part.id)
                    } else {
                        arManager?.highlightPart(named: part.modelPartName ?? part.id)
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
        }
    }
    
    private var rootSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BotanicalCard(
                title: plant.rootType.description,
                content: "Understanding root systems helps us learn how plants absorb water and nutrients from soil.",
                icon: "🌱"
            )
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(icon: "💧", text: "Roots absorb water through osmosis.")
                InfoRow(icon: "🏗️", text: "Provides structural stability in wind and soil.")
                InfoRow(icon: "🔬", text: "Root hairs increase surface area for absorption.")
            }
            .padding(.leading, 4)
        }
    }
    
    private var factsSection: some View {
        VStack(spacing: 12) {
            ForEach(plant.funFacts, id: \.self) { fact in
                HStack(alignment: .top, spacing: 15) {
                    Image(systemName: "sparkles").foregroundColor(.orange)
                    Text(fact)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    private var quizSection: some View {
        VStack(spacing: PlantSpacing.xl) {
            // Quiz intro card
            VStack(spacing: PlantSpacing.lg) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundColor(.plantPrimary)

                Text("Test Your Knowledge")
                    .font(.displaySmall)
                    .foregroundColor(.textPrimary)

                Text("Answer questions about \(plant.commonName) to earn mastery and track your learning progress.")
                    .font(.bodyMedium)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: PlantSpacing.lg) {
                    VStack(spacing: 4) {
                        Text("\(plant.quizQuestions.count)")
                            .font(.titleLarge)
                            .foregroundColor(.plantPrimary)
                        Text("Questions")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack(spacing: 4) {
                        Text("80%")
                            .font(.titleLarge)
                            .foregroundColor(.botanicalSuccess)
                        Text("To Master")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.top, PlantSpacing.sm)
            }
            .padding(PlantSpacing.xl)
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(PlantRadius.lg)

            // Start quiz button
            Button(action: {
                showQuizFullScreen = true
            }) {
                HStack(spacing: PlantSpacing.sm) {
                    Image(systemName: "play.fill")
                    Text("Start Quiz")
                }
            }
            .buttonStyle(PlantPrimaryButtonStyle())

            // Previous attempts (if any)
            if let studentID = auth.currentStudentID,
               let record = persistence.getRecord(for: plant.id, studentID: studentID),
               record.quizCompleted {
                previousAttemptCard(record: record)
            }
        }
    }

    private func previousAttemptCard(record: GardenRecord) -> some View {
        VStack(alignment: .leading, spacing: PlantSpacing.md) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.textSecondary)
                Text("Previous Attempt")
                    .font(.labelLarge)
                    .foregroundColor(.textSecondary)
                Spacer()
            }

            if let score = record.quizScore {
                HStack {
                    Text("Score: \(Int(score * 100))%")
                        .font(.titleMedium)
                        .foregroundColor(score >= 0.8 ? .botanicalSuccess : .textPrimary)

                    Spacer()

                    if score >= 0.8 {
                        Label("Mastered", systemImage: "checkmark.seal.fill")
                            .font(.labelMedium)
                            .foregroundColor(.botanicalSuccess)
                    }
                }
            }
        }
        .padding(PlantSpacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.md)
    }

    private var footerView: some View {
        VStack(spacing: 12) {
            if timeSpent > 2 {
                Text("Engaged for \(timeSpent) seconds")
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            
            Button("Finish Exploration") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Supporting Components

struct HeaderView: View {
    let plant: Plant
    let dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(plant.commonName)
                        .font(.title2)
                        .bold()
                    Text(plant.scientificName)
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
}

struct TabSelector: View {
    @Binding var selectedTab: MerlinStylePlantInfoSheet.InfoTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(MerlinStylePlantInfoSheet.InfoTab.allCases, id: \.self) { tab in
                VStack(spacing: 8) {
                    Image(systemName: tab.icon)
                    Text(tab.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedTab = tab
                }
            }
        }
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .overlay(Divider(), alignment: .bottom)
    }
}

struct BotanicalCard: View {
    let title: String
    let content: String
    let icon: String?
    
    init(title: String, content: String, icon: String? = nil) {
        self.title = title
        self.content = content
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct PartCard: View {
    let part: PlantPart
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(part.name)
                        .font(.body)
                        .fontWeight(.semibold)
                    Text(part.scientificName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isHighlighted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }
            }
            
            Text(part.function)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineSpacing(1)
        }
        .padding(10)
        .background(isHighlighted ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
}

struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 24))
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
