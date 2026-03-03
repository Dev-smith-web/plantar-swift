import SwiftUI
import FirebaseCore

@main
struct PlantARApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var teacherAuthService = TeacherAuthService()
    @StateObject private var persistenceService = PersistenceService.shared

    init() {
        FirebaseApp.configure()
        PlantTabStyle.configure()
        PlantNavigationStyle.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if teacherAuthService.isTeacher {
                    TeacherDashboardView()
                        .environmentObject(teacherAuthService)
                        .environmentObject(persistenceService)
                } else if authService.isAuthenticated {
                    MainTabView()
                        .environmentObject(authService)
                        .environmentObject(persistenceService)
                } else {
                    NavigationView {
                        EntrySelectionView()
                    }
                    .navigationViewStyle(.stack)
                    .environmentObject(authService)
                    .environmentObject(teacherAuthService)
                }
            }
            .tint(.plantPrimary)
        }
    }
}
