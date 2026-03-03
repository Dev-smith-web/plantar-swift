import SwiftUI

@main
struct PlantARApp: App {
    // Shared services initialized at the App level
    @StateObject private var authService = AuthService()
    @StateObject private var teacherAuthService = TeacherAuthService()
    @StateObject private var persistenceService = PersistenceService.shared

    init() {
        // Configure app-wide styling
        PlantTabStyle.configure()
        PlantNavigationStyle.configure()
    }

    var body: some Scene {
        WindowGroup {
            // Root View Selector: Swaps views based on login state
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
                    // Start screen for choosing Student or Teacher path
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
