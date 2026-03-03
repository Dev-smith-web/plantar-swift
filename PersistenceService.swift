import Foundation
import Combine

// MARK: - Garden Record

struct GardenRecord: Codable, Identifiable, Hashable {
    let id: String
    let plantID: String
    let studentID: String
    let scannedDate: Date
    var quizCompleted: Bool = false
    var quizScore: Float? = nil
    var timeSpentSeconds: Int = 0
    var isSynced: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, plantID, studentID, scannedDate
        case quizCompleted, quizScore, timeSpentSeconds, isSynced
    }
}

// MARK: - Persistence Service

class PersistenceService: ObservableObject {
    static let shared = PersistenceService()
    
    @Published var myGarden: [GardenRecord] = []
    @Published var plantOfTheDay: Plant?
    @Published var isSyncing = false
    @Published var syncError: String? = nil
    
    private let userDefaults = UserDefaults.standard
    private let gardenKey = "plantAR_garden_v1"
    private let potdKey = "plantAR_potd_v1"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadLocalData()
        refreshPlantOfTheDay()
        setupAutoSync()
    }
    
    // MARK: - Core Logic
    
    private func setupAutoSync() {
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncUnsyncedRecords()
            }
            .store(in: &cancellables)
    }
    
    func addToGarden(plantID: String, studentID: String) {
        guard !hasScanned(plantID, by: studentID) else { return }
        
        let newRecord = GardenRecord(
            id: UUID().uuidString,
            plantID: plantID,
            studentID: studentID,
            scannedDate: Date()
        )
        
        myGarden.append(newRecord)
        saveToLocal()
        syncUnsyncedRecords()
    }
    
    func updateProgress(plantID: String, studentID: String, score: Float, timeSpent: Int) {
        if let index = myGarden.firstIndex(where: { $0.plantID == plantID && $0.studentID == studentID }) {
            myGarden[index].quizCompleted = true
            myGarden[index].quizScore = score
            myGarden[index].timeSpentSeconds += timeSpent
            myGarden[index].isSynced = false

            saveToLocal()
            syncUnsyncedRecords()
        }
    }

    /// Adds time spent viewing a plant without touching quiz score or completion status
    func addTimeSpent(plantID: String, studentID: String, timeSpent: Int) {
        if let index = myGarden.firstIndex(where: { $0.plantID == plantID && $0.studentID == studentID }) {
            myGarden[index].timeSpentSeconds += timeSpent
            myGarden[index].isSynced = false
            saveToLocal()
        }
    }
    
    // MARK: - Queries
    
    func hasScanned(_ plantID: String, by studentID: String) -> Bool {
        myGarden.contains { $0.plantID == plantID && $0.studentID == studentID }
    }
    
    func getRecord(for plantID: String, studentID: String) -> GardenRecord? {
        myGarden.first { $0.plantID == plantID && $0.studentID == studentID }
    }
    
    func refreshPlantOfTheDay() {
        self.plantOfTheDay = getPlantOfTheDay()
    }
    
    // MARK: - Data Persistence
    
    private func saveToLocal() {
        if let encoded = try? JSONEncoder().encode(myGarden) {
            userDefaults.set(encoded, forKey: gardenKey)
        }
    }
    
    private func loadLocalData() {
        if let data = userDefaults.data(forKey: gardenKey),
           let decoded = try? JSONDecoder().decode([GardenRecord].self, from: data) {
            self.myGarden = decoded
        }
    }
    
    // MARK: - Cloud Sync
    
    func syncNow() {
        syncUnsyncedRecords()
    }
    
    private func syncUnsyncedRecords() {
        let unsynced = myGarden.filter { !$0.isSynced }
        guard !unsynced.isEmpty && !isSyncing else { return }
        
        isSyncing = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                for index in myGarden.indices {
                    if !myGarden[index].isSynced {
                        myGarden[index].isSynced = true
                    }
                }
                self.isSyncing = false
                self.saveToLocal()
            }
        }
    }
}

// MARK: - Garden State

enum GardenPlantState {
    case locked
    case discovered(record: GardenRecord)
    case mastered(record: GardenRecord)
    
    var isUnlocked: Bool {
        if case .locked = self { return false }
        return true
    }
    
    var statusLabel: String {
        switch self {
        case .locked:
            return "Find in the wild"
        case .discovered(let record):
            return "Found \(record.scannedDate.formatted(.dateTime.month().day()))"
        case .mastered(let record):
            let pct = Int((record.quizScore ?? 0) * 100)
            return "Mastered: \(pct)%"
        }
    }
}

func resolveGardenState(for plant: Plant, studentID: String?) -> GardenPlantState {
    guard let studentID = studentID else { return .locked }
    
    if let record = PersistenceService.shared.getRecord(for: plant.id, studentID: studentID) {
        return record.quizCompleted ? .mastered(record: record) : .discovered(record: record)
    }
    
    return .locked
}

// MARK: - Teacher Analytics Extension

extension PersistenceService {
    
    struct StudentSummary: Identifiable {
        let id: String
        let name: String
        let scannedCount: Int
        let quizCount: Int
        let averageScore: Float
    }
    
    func getAllStudents(for classCode: String) -> [StudentSummary] {
        let studentIDs = Set(UserDefaults.standard.stringArray(forKey: "class_\(classCode)") ?? [])
        let allRecords = studentIDs.isEmpty ? [] : self.myGarden.filter { studentIDs.contains($0.studentID) }
        let groupedByStudent = Dictionary(grouping: allRecords, by: { $0.studentID })
        var summaries: [StudentSummary] = []
        
        for (email, records) in groupedByStudent {
            let scannedCount = records.count
            let completedQuizzes = records.filter { $0.quizCompleted }
            let quizCount = completedQuizzes.count
            let totalScore = completedQuizzes.compactMap { $0.quizScore }.reduce(0, +)
            let avgScore = quizCount > 0 ? (totalScore / Float(quizCount)) : 0.0
            
            let displayName = email.split(separator: "@").first.map(String.init)?.capitalized ?? "Student"
            
            summaries.append(StudentSummary(
                id: email,
                name: displayName,
                scannedCount: scannedCount,
                quizCount: quizCount,
                averageScore: avgScore
            ))
        }
        return summaries.sorted { $0.averageScore > $1.averageScore }
    }
    
    func getStudentGarden(for studentID: String) -> [GardenRecord] {
        myGarden.filter { $0.studentID == studentID }
            .sorted { $0.scannedDate > $1.scannedDate }
    }
}
