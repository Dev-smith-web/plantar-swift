import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class TeacherAuthService: ObservableObject {
    @Published var isTeacher = false
    @Published var teacherEmail: String? = nil
    @Published var teacherName: String? = nil
    @Published var classCode: String? = nil

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            guard let user = user else {
                DispatchQueue.main.async {
                    self.isTeacher = false
                    self.teacherEmail = nil
                    self.teacherName = nil
                    self.classCode = nil
                }
                return
            }
            // Check if this user has a teacher document
            self.db.collection("teachers").document(user.uid).getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                DispatchQueue.main.async {
                    self.teacherEmail = data["email"] as? String
                    self.teacherName = data["name"] as? String
                    self.classCode = data["classCode"] as? String
                    self.isTeacher = true
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func authenticateTeacher(email: String, password: String, isNewUser: Bool) async throws {
        let lowercasedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        if isNewUser {
            // New teacher — create account and Firestore doc
            let result = try await Auth.auth().createUser(withEmail: lowercasedEmail, password: password)
            let uid = result.user.uid
            let name = lowercasedEmail.split(separator: "@").first.map(String.init)?.capitalized ?? "Teacher"
            let generatedCode = String(UUID().uuidString.prefix(6)).uppercased()

            try await db.collection("teachers").document(uid).setData([
                "email": lowercasedEmail,
                "name": name,
                "classCode": generatedCode,
                "createdAt": FieldValue.serverTimestamp()
            ])
            // Auth state listener picks up the new doc and sets isTeacher = true
        } else {
            // Returning teacher — sign in
            let result = try await Auth.auth().signIn(withEmail: lowercasedEmail, password: password)
            let doc = try await db.collection("teachers").document(result.user.uid).getDocument()
            if !doc.exists {
                try? Auth.auth().signOut()
                throw NSError(domain: "Auth", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "No teacher account found. Please register as a new teacher first."
                ])
            }
            // Auth state listener updates published properties
        }
    }

    func logout() {
        try? Auth.auth().signOut()
    }
}
