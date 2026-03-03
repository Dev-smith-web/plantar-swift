import Foundation
import Combine

/// Manages student authentication and session persistence
class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentStudentID: String? = nil
    @Published var currentStudentName: String? = nil
    @Published var classCode: String = ""
    
    init() {
        // Restore session from local storage on app launch
        if let savedID = UserDefaults.standard.string(forKey: "studentID") {
            self.currentStudentID = savedID
            self.currentStudentName = UserDefaults.standard.string(forKey: "studentName")
            self.classCode = UserDefaults.standard.string(forKey: "classCode") ?? ""
            self.isAuthenticated = true
        }
    }
    
    /// Logs a student in and persists their info to the device
    func login(email: String, name: String, classCode: String) async throws {
        // Simulate network latency (1 second)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
            let formattedCode = classCode.uppercased().trimmingCharacters(in: .whitespaces)
            
            self.currentStudentID = normalizedEmail
            self.currentStudentName = name
            self.classCode = formattedCode
            self.isAuthenticated = true
            
            // Save to UserDefaults
            UserDefaults.standard.set(normalizedEmail, forKey: "studentID")
            UserDefaults.standard.set(name, forKey: "studentName")
            UserDefaults.standard.set(formattedCode, forKey: "classCode")

            // Register student under their class code so teachers can look them up
            var classMembers = UserDefaults.standard.stringArray(forKey: "class_\(formattedCode)") ?? []
            if !classMembers.contains(normalizedEmail) {
                classMembers.append(normalizedEmail)
                UserDefaults.standard.set(classMembers, forKey: "class_\(formattedCode)")
            }
        }
    }
    
    /// Clears student session data
    func logout() {
        isAuthenticated = false
        currentStudentID = nil
        currentStudentName = nil
        classCode = ""
        
        UserDefaults.standard.removeObject(forKey: "studentID")
        UserDefaults.standard.removeObject(forKey: "studentName")
        UserDefaults.standard.removeObject(forKey: "classCode")
    }
}
