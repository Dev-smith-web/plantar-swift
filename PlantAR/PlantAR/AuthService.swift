import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentStudentID: String? = nil
    @Published var currentStudentName: String? = nil
    @Published var classCode: String = ""

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            guard let user = user else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.currentStudentID = nil
                    self.currentStudentName = nil
                    self.classCode = ""
                }
                return
            }
            // Verify this user has a student document (not a teacher)
            self.db.collection("students").document(user.uid).getDocument { snapshot, _ in
                guard let data = snapshot?.data() else { return }
                DispatchQueue.main.async {
                    self.currentStudentID = user.uid
                    self.currentStudentName = data["name"] as? String
                    self.classCode = data["classCode"] as? String ?? ""
                    self.isAuthenticated = true
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func login(email: String, name: String, classCode: String, password: String, isNewUser: Bool) async throws {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        let formattedCode = classCode.uppercased().trimmingCharacters(in: .whitespaces)

        if isNewUser {
            // Sign up — create new account
            let result = try await Auth.auth().createUser(withEmail: normalizedEmail, password: password)
            try await db.collection("students").document(result.user.uid).setData([
                "name": name,
                "email": normalizedEmail,
                "classCode": formattedCode,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } else {
            // Sign in — returning student, profile already exists in Firestore
            try await Auth.auth().signIn(withEmail: normalizedEmail, password: password)
        }
        // Auth state listener updates published properties automatically
    }

    func logout() {
        try? Auth.auth().signOut()
    }

    func updateProfile(name: String, classCode: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedCode = classCode.uppercased().trimmingCharacters(in: .whitespaces)
        try await db.collection("students").document(uid).updateData([
            "name": trimmedName,
            "classCode": trimmedCode
        ])
        await MainActor.run {
            self.currentStudentName = trimmedName
            self.classCode = trimmedCode
        }
    }
}
