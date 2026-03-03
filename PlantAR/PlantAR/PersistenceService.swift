import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Garden Record

struct GardenRecord: Codable, Identifiable, Hashable {
    let id: String
    let plantID: String
    let studentID: String
    let scannedDate: Date
    var quizCompleted: Bool = false
    var quizScore: Float? = nil
    var timeSpentSeconds: Int = 0
}

// MARK: - Persistence Service

class PersistenceService: ObservableObject {
    static let shared = PersistenceService()

    @Published var myGarden: [GardenRecord] = []
    @Published var plantOfTheDay: Plant?
    @Published var isSyncing = false
    @Published var studentSummaries: [StudentSummary] = []

    private let db = Firestore.firestore()
    private var gardenListener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        refreshPlantOfTheDay()
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.gardenListener?.remove()
            if let user = user {
                self.attachGardenListener(for: user.uid)
            } else {
                DispatchQueue.main.async { self.myGarden = [] }
            }
        }
    }

    private func attachGardenListener(for uid: String) {
        gardenListener = db.collection("students").document(uid).collection("garden")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let documents = snapshot?.documents else { return }
                let records: [GardenRecord] = documents.compactMap { doc in
                    let data = doc.data()
                    guard let plantID = data["plantID"] as? String,
                          let studentID = data["studentID"] as? String,
                          let timestamp = data["scannedDate"] as? Timestamp else { return nil }
                    return GardenRecord(
                        id: doc.documentID,
                        plantID: plantID,
                        studentID: studentID,
                        scannedDate: timestamp.dateValue(),
                        quizCompleted: data["quizCompleted"] as? Bool ?? false,
                        quizScore: data["quizScore"] as? Float,
                        timeSpentSeconds: data["timeSpentSeconds"] as? Int ?? 0
                    )
                }
                DispatchQueue.main.async { self.myGarden = records }
            }
    }

    // MARK: - Core Logic

    func addToGarden(plantID: String, studentID: String) {
        guard !hasScanned(plantID, by: studentID),
              let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("students").document(uid).collection("garden").addDocument(data: [
            "plantID": plantID,
            "studentID": studentID,
            "scannedDate": FieldValue.serverTimestamp(),
            "quizCompleted": false,
            "timeSpentSeconds": 0
        ])
    }

    func updateProgress(plantID: String, studentID: String, score: Float, timeSpent: Int) {
        guard let uid = Auth.auth().currentUser?.uid,
              let record = getRecord(for: plantID, studentID: studentID) else { return }

        db.collection("students").document(uid).collection("garden").document(record.id).updateData([
            "quizCompleted": true,
            "quizScore": score,
            "timeSpentSeconds": FieldValue.increment(Int64(timeSpent))
        ])
    }

    func addTimeSpent(plantID: String, studentID: String, timeSpent: Int) {
        guard let uid = Auth.auth().currentUser?.uid,
              let record = getRecord(for: plantID, studentID: studentID) else { return }

        db.collection("students").document(uid).collection("garden").document(record.id).updateData([
            "timeSpentSeconds": FieldValue.increment(Int64(timeSpent))
        ])
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

    func syncNow() {} // No-op — Firestore is always real-time
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
        let email: String
        let scannedCount: Int
        let quizCount: Int
        let averageScore: Float
    }

    /// Fetches all students in a class from Firestore and updates studentSummaries
    func refreshStudentSummaries(for classCode: String) async {
        guard !classCode.isEmpty else { return }
        do {
            let snapshot = try await db.collection("students")
                .whereField("classCode", isEqualTo: classCode)
                .getDocuments()

            var summaries: [StudentSummary] = []
            for doc in snapshot.documents {
                let data = doc.data()
                let uid = doc.documentID
                let name = data["name"] as? String ?? "Student"
                let email = data["email"] as? String ?? ""

                let gardenSnap = try await db.collection("students").document(uid)
                    .collection("garden").getDocuments()
                let allRecords = gardenSnap.documents
                let completed = allRecords.filter { $0.data()["quizCompleted"] as? Bool == true }
                let scores = completed.compactMap { $0.data()["quizScore"] as? Float }
                let avgScore = completed.isEmpty ? 0 : scores.reduce(0, +) / Float(completed.count)

                summaries.append(StudentSummary(
                    id: uid,
                    name: name,
                    email: email,
                    scannedCount: allRecords.count,
                    quizCount: completed.count,
                    averageScore: avgScore
                ))
            }
            let sorted = summaries.sorted { $0.averageScore > $1.averageScore }
            await MainActor.run { self.studentSummaries = sorted }
        } catch {
            print("Failed to fetch student summaries: \(error)")
        }
    }

    func getStudentGarden(for studentID: String) -> [GardenRecord] {
        myGarden.filter { $0.studentID == studentID }
            .sorted { $0.scannedDate > $1.scannedDate }
    }
}
