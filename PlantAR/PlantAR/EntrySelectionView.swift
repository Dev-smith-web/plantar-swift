import SwiftUI

struct EntrySelectionView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var teacherAuth: TeacherAuthService

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.naturalCream,
                    Color.pageBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative botanical elements
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.plantPrimary.opacity(0.06))
                        .frame(width: 300, height: 300)
                        .offset(x: 100, y: -80)
                }
                Spacer()
                HStack {
                    Circle()
                        .fill(Color.leafOlive.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .offset(x: -60, y: 40)
                    Spacer()
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero Section
                VStack(spacing: PlantSpacing.xl) {
                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color.plantPrimary, Color.plantPrimaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.plantPrimary.opacity(0.3), radius: 16, x: 0, y: 8)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: PlantSpacing.sm) {
                        Text("PlantAR")
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)

                        Text("Discover the botanical world through augmented reality")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, PlantSpacing.xxl)
                    }
                }

                Spacer()

                // Entry Options
                VStack(spacing: PlantSpacing.lg) {
                    // Student Entry
                    NavigationLink(destination: LoginView().environmentObject(auth)) {
                        HStack(spacing: PlantSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Continue as Student")
                                    .font(.titleSmall)
                                    .foregroundColor(.white)

                                Text("Scan plants and track your discoveries")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(PlantSpacing.lg)
                        .background(
                            LinearGradient(
                                colors: [Color.plantPrimary, Color.plantPrimaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(PlantRadius.lg)
                        .shadow(color: Color.plantPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }

                    // Teacher Entry
                    NavigationLink(destination: TeacherLoginView().environmentObject(teacherAuth)) {
                        HStack(spacing: PlantSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.teacherBlue.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.teacherBlue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Teacher Portal")
                                    .font(.titleSmall)
                                    .foregroundColor(.textPrimary)

                                Text("Manage classes and view student progress")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textTertiary)
                        }
                        .padding(PlantSpacing.lg)
                        .background(Color.cardBackground)
                        .cornerRadius(PlantRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: PlantRadius.lg)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, PlantSpacing.xl)

                Spacer()
                    .frame(height: PlantSpacing.xxl)

                // Footer
                VStack(spacing: PlantSpacing.xs) {
                    Text("PlantAR v1.0")
                        .font(.caption)
                        .foregroundColor(.textTertiary)

                    Text("University of North Texas • Capstone Project")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(.bottom, PlantSpacing.xl)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        EntrySelectionView()
            .environmentObject(AuthService())
            .environmentObject(TeacherAuthService())
    }
}
