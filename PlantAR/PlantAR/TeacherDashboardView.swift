import SwiftUI

struct TeacherDashboardView: View {
    @EnvironmentObject var teacherAuth: TeacherAuthService
    @EnvironmentObject var persistence: PersistenceService
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TeacherOverviewTab()
                .tabItem { Label("Overview", systemImage: "chart.bar.fill") }
                .tag(0)

            TeacherStudentsTab()
                .tabItem { Label("Students", systemImage: "person.2.fill") }
                .tag(1)

            TeacherPlantsTab()
                .tabItem { Label("Plants", systemImage: "leaf.fill") }
                .tag(2)

            TeacherSettingsTab()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3)
        }
        .tint(.teacherBlue)
        .environmentObject(teacherAuth)
        .environmentObject(persistence)
    }
}

// MARK: - Overview Tab

struct TeacherOverviewTab: View {
    @EnvironmentObject var teacherAuth: TeacherAuthService
    @EnvironmentObject var persistence: PersistenceService
    @State private var showingCopyAlert = false

    var students: [PersistenceService.StudentSummary] {
        persistence.studentSummaries
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PlantSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: PlantSpacing.xs) {
                        Text("Dashboard")
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)

                        if let name = teacherAuth.teacherName {
                            Text("Welcome, \(name)")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlantSpacing.xl)
                    .padding(.top, PlantSpacing.md)

                    // Class Code Card
                    ClassCodeCard(
                        classCode: teacherAuth.classCode ?? "------",
                        onCopy: {
                            UIPasteboard.general.string = teacherAuth.classCode
                            showingCopyAlert = true
                        }
                    )
                    .padding(.horizontal, PlantSpacing.xl)

                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PlantSpacing.md) {
                        TeacherStatCard(
                            icon: "person.2.fill",
                            iconColor: .teacherBlue,
                            value: "\(students.count)",
                            label: "Students"
                        )

                        TeacherStatCard(
                            icon: "leaf.fill",
                            iconColor: .plantPrimary,
                            value: "\(students.reduce(0) { $0 + $1.scannedCount })",
                            label: "Total Scans"
                        )

                        TeacherStatCard(
                            icon: "chart.line.uptrend.xyaxis",
                            iconColor: .botanicalSuccess,
                            value: students.isEmpty ? "0%" : String(format: "%.0f%%", students.reduce(0) { $0 + $1.averageScore } / Float(students.count) * 100),
                            label: "Avg Score"
                        )

                        TeacherStatCard(
                            icon: "star.fill",
                            iconColor: .botanicalWarning,
                            value: "\(students.filter { $0.averageScore >= 0.8 }.count)",
                            label: "Mastery"
                        )
                    }
                    .padding(.horizontal, PlantSpacing.xl)

                    // Recent Activity
                    if !students.isEmpty {
                        VStack(alignment: .leading, spacing: PlantSpacing.md) {
                            Text("Top Performers")
                                .font(.titleMedium)
                                .foregroundColor(.textPrimary)

                            ForEach(students.prefix(3)) { student in
                                TopStudentRow(student: student)
                            }
                        }
                        .padding(.horizontal, PlantSpacing.xl)
                    }
                }
                .padding(.bottom, PlantSpacing.xxl)
            }
            .background(Color.pageBackground)
            .navigationBarHidden(true)
        }
        .alert("Copied!", isPresented: $showingCopyAlert) {
            Button("OK", role: .cancel) {}
        }
        .task {
            await persistence.refreshStudentSummaries(for: teacherAuth.classCode ?? "")
        }
    }
}

// MARK: - Class Code Card

struct ClassCodeCard: View {
    let classCode: String
    let onCopy: () -> Void

    var body: some View {
        Button(action: onCopy) {
            HStack {
                VStack(alignment: .leading, spacing: PlantSpacing.xs) {
                    Text("CLASS CODE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.teacherBlue)

                    Text(classCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.textPrimary)

                    Text("Tap to copy and share with students")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.teacherBlue)
            }
            .padding(PlantSpacing.xl)
            .background(Color.teacherBlue.opacity(0.08))
            .cornerRadius(PlantRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: PlantRadius.lg)
                    .stroke(Color.teacherBlue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Teacher Stat Card

struct TeacherStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: PlantSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            Text(value)
                .font(.titleLarge)
                .foregroundColor(.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(PlantSpacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.md)
    }
}

// MARK: - Top Student Row

struct TopStudentRow: View {
    let student: PersistenceService.StudentSummary

    var body: some View {
        HStack(spacing: PlantSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.teacherBlue.opacity(0.1))
                    .frame(width: 44, height: 44)

                Text(String(student.name.prefix(1)).uppercased())
                    .font(.titleSmall)
                    .foregroundColor(.teacherBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)

                Text("\(student.scannedCount) plants scanned")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(String(format: "%.0f%%", student.averageScore * 100))
                .font(.titleMedium)
                .foregroundColor(student.averageScore >= 0.8 ? .botanicalSuccess : .textPrimary)
        }
        .padding(PlantSpacing.md)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.md)
    }
}

// MARK: - Students Tab

struct TeacherStudentsTab: View {
    @EnvironmentObject var teacherAuth: TeacherAuthService
    @EnvironmentObject var persistence: PersistenceService

    var students: [PersistenceService.StudentSummary] {
        persistence.studentSummaries
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PlantSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: PlantSpacing.xs) {
                        Text("Students")
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)

                        Text("\(students.count) enrolled in class")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlantSpacing.xl)
                    .padding(.top, PlantSpacing.md)

                    if students.isEmpty {
                        // Empty State
                        VStack(spacing: PlantSpacing.lg) {
                            Spacer(minLength: PlantSpacing.xxxl)

                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 64))
                                .foregroundColor(.textTertiary.opacity(0.5))

                            Text("No students yet")
                                .font(.titleMedium)
                                .foregroundColor(.textPrimary)

                            Text("Share your class code with students to get started. They'll appear here once they join.")
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, PlantSpacing.xxl)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        // Student List
                        VStack(spacing: PlantSpacing.md) {
                            ForEach(students) { student in
                                StudentDetailCard(student: student)
                            }
                        }
                        .padding(.horizontal, PlantSpacing.xl)
                    }
                }
                .padding(.bottom, PlantSpacing.xxl)
            }
            .background(Color.pageBackground)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Student Detail Card

struct StudentDetailCard: View {
    let student: PersistenceService.StudentSummary

    var body: some View {
        VStack(alignment: .leading, spacing: PlantSpacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.teacherBlue.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(String(student.name.prefix(1)).uppercased())
                        .font(.titleMedium)
                        .foregroundColor(.teacherBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(student.name)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)

                    Text(student.email)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", student.averageScore * 100))
                        .font(.titleMedium)
                        .foregroundColor(student.averageScore >= 0.8 ? .botanicalSuccess : .textPrimary)

                    if student.averageScore >= 0.8 {
                        Label("Mastery", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.botanicalWarning)
                    }
                }
            }

            Divider()

            HStack(spacing: PlantSpacing.xl) {
                HStack(spacing: PlantSpacing.xs) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.plantPrimary)
                    Text("\(student.scannedCount) scanned")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                HStack(spacing: PlantSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.botanicalSuccess)
                    Text("\(student.quizCount) quizzes")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(PlantSpacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.lg)
    }
}

// MARK: - Plants Tab

struct TeacherPlantsTab: View {
    @EnvironmentObject var persistence: PersistenceService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PlantSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: PlantSpacing.xs) {
                        Text("Plant Engagement")
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)

                        Text("See how students interact with each plant")
                            .font(.bodyMedium)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlantSpacing.xl)
                    .padding(.top, PlantSpacing.md)

                    // Plant List
                    VStack(spacing: PlantSpacing.md) {
                        ForEach(plantDatabase) { plant in
                            PlantEngagementCard(plant: plant)
                        }
                    }
                    .padding(.horizontal, PlantSpacing.xl)
                }
                .padding(.bottom, PlantSpacing.xxl)
            }
            .background(Color.pageBackground)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Plant Engagement Card

struct PlantEngagementCard: View {
    let plant: Plant
    @EnvironmentObject var persistence: PersistenceService

    var scans: Int {
        persistence.myGarden.filter { $0.plantID == plant.id }.count
    }

    var quizzes: Int {
        persistence.myGarden.filter { $0.plantID == plant.id && $0.quizCompleted }.count
    }

    var body: some View {
        HStack(spacing: PlantSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color(hex: plant.color).opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: plant.color))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.commonName)
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)

                Text(plant.scientificName)
                    .font(.scientificSmall)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(scans)")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)

                Text("scans")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(PlantSpacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.lg)
    }
}

// MARK: - Settings Tab

struct TeacherSettingsTab: View {
    @EnvironmentObject var teacherAuth: TeacherAuthService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: PlantSpacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: PlantSpacing.xs) {
                        Text("Settings")
                            .font(.displayLarge)
                            .foregroundColor(.textPrimary)

                        if let email = teacherAuth.teacherEmail {
                            Text(email)
                                .font(.bodyMedium)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlantSpacing.xl)
                    .padding(.top, PlantSpacing.md)

                    // Account Section
                    VStack(alignment: .leading, spacing: PlantSpacing.md) {
                        Text("ACCOUNT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal, PlantSpacing.xl)

                        VStack(spacing: 1) {
                            SettingsRow(
                                icon: "person.fill",
                                title: "Teacher Name",
                                value: teacherAuth.teacherName ?? "Unknown"
                            )

                            SettingsRow(
                                icon: "number",
                                title: "Class Code",
                                value: teacherAuth.classCode ?? "------"
                            )
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(PlantRadius.md)
                        .padding(.horizontal, PlantSpacing.xl)
                    }

                    // Actions Section
                    VStack(alignment: .leading, spacing: PlantSpacing.md) {
                        Text("ACTIONS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal, PlantSpacing.xl)

                        Button(action: {
                            if let code = teacherAuth.classCode {
                                UIPasteboard.general.string = code
                            }
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.teacherBlue)
                                Text("Copy Class Code")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(PlantSpacing.lg)
                            .background(Color.cardBackground)
                            .cornerRadius(PlantRadius.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, PlantSpacing.xl)
                    }

                    Spacer(minLength: PlantSpacing.xxxl)

                    // Logout
                    Button(action: { teacherAuth.logout() }) {
                        Text("Sign Out")
                            .font(.titleSmall)
                            .foregroundColor(.botanicalError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, PlantSpacing.lg)
                            .background(Color.botanicalError.opacity(0.1))
                            .cornerRadius(PlantRadius.md)
                    }
                    .padding(.horizontal, PlantSpacing.xl)
                }
                .padding(.bottom, PlantSpacing.xxl)
            }
            .background(Color.pageBackground)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: PlantSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.teacherBlue)
                .frame(width: 24)

            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
        }
        .padding(PlantSpacing.lg)
    }
}

#Preview {
    TeacherDashboardView()
        .environmentObject(TeacherAuthService())
        .environmentObject(PersistenceService.shared)
}
