import Foundation
import Combine

/// Manages teacher portal access and classroom code generation
class TeacherAuthService: ObservableObject {
    @Published var isTeacher = false
    @Published var teacherEmail: String? = nil
    @Published var teacherName: String? = nil
    @Published var classCode: String? = nil
    
    init() {
        // Load existing teacher session if available
        if let savedCode = UserDefaults.standard.string(forKey: "teacherClassCode") {
            self.classCode = savedCode
            self.teacherEmail = UserDefaults.standard.string(forKey: "teacherEmail")
            self.teacherName = UserDefaults.standard.string(forKey: "teacherName")
            self.isTeacher = true
        }
    }
    
    /// Validates teacher credentials and generates a unique class code
    func authenticateTeacher(email: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Basic validation for educational domains
        let lowercasedEmail = email.lowercased()
        if lowercasedEmail.hasSuffix(".edu") || lowercasedEmail.contains("school") {
            
            // Generate a random 6-character unique identifier for the classroom
            let generatedCode = String(UUID().uuidString.prefix(6)).uppercased()
            
            await MainActor.run {
                self.teacherEmail = lowercasedEmail
                self.teacherName = email.split(separator: "@").first.map(String.init)?.capitalized ?? "Teacher"
                self.classCode = generatedCode
                self.isTeacher = true
                
                // Persist session
                UserDefaults.standard.set(generatedCode, forKey: "teacherClassCode")
                UserDefaults.standard.set(lowercasedEmail, forKey: "teacherEmail")
                UserDefaults.standard.set(self.teacherName, forKey: "teacherName")
            }
        } else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please use a valid school email address (.edu)."])
        }
    }
    
    func logout() {
        isTeacher = false
        teacherEmail = nil
        teacherName = nil
        classCode = nil
        
        UserDefaults.standard.removeObject(forKey: "teacherClassCode")
        UserDefaults.standard.removeObject(forKey: "teacherEmail")
        UserDefaults.standard.removeObject(forKey: "teacherName")
    }
}
