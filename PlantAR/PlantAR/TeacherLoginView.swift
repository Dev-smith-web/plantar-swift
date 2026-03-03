import SwiftUI

struct TeacherLoginView: View {
    @EnvironmentObject var teacherAuth: TeacherAuthService
    @Environment(\.dismiss) var dismiss

    @State private var isNewTeacher = true
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @FocusState private var isFieldFocused: Bool

    var isFormValid: Bool {
        email.contains("@") && password.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PlantSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: PlantSpacing.sm) {
                    HStack(spacing: PlantSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.teacherBlue.opacity(0.1))
                                .frame(width: 56, height: 56)

                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.teacherBlue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Teacher Portal")
                                .font(.displayMedium)
                                .foregroundColor(.textPrimary)

                            Text("Educator Access")
                                .font(.labelMedium)
                                .foregroundColor(.teacherBlue)
                        }
                    }

                    Text("Create a virtual classroom and generate a unique code to share with your students. Track their progress and engagement in real-time.")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, PlantSpacing.sm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, PlantSpacing.lg)

                // New / Returning toggle
                Picker("", selection: $isNewTeacher) {
                    Text("New Teacher").tag(true)
                    Text("Returning Teacher").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: isNewTeacher) { _, _ in errorMessage = "" }

                // Email Input
                VStack(alignment: .leading, spacing: PlantSpacing.sm) {
                    Text("School Email")
                        .font(.labelLarge)
                        .foregroundColor(.textSecondary)

                    HStack(spacing: PlantSpacing.md) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isFieldFocused ? .teacherBlue : .textTertiary)
                            .frame(width: 20)

                        TextField("teacher@school.edu", text: $email)
                            .font(.bodyLarge)
                            .foregroundColor(.textPrimary)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($isFieldFocused)

                        if !email.isEmpty {
                            Button(action: { email = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.textTertiary)
                            }
                        }
                    }
                    .padding(PlantSpacing.lg)
                    .background(Color.cardBackground)
                    .cornerRadius(PlantRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: PlantRadius.md)
                            .stroke(isFieldFocused ? Color.teacherBlue : Color.clear, lineWidth: 2)
                    )

                }

                // Password Input
                VStack(alignment: .leading, spacing: PlantSpacing.sm) {
                    Text("Password")
                        .font(.labelLarge)
                        .foregroundColor(.textSecondary)

                    SecureFormField(
                        title: "",
                        placeholder: "Create or enter your password",
                        text: $password
                    )
                }

                // Info Card
                VStack(alignment: .leading, spacing: PlantSpacing.md) {
                    Label("What happens next?", systemImage: "info.circle.fill")
                        .font(.titleSmall)
                        .foregroundColor(.teacherBlue)

                    VStack(alignment: .leading, spacing: PlantSpacing.sm) {
                        InfoStep(number: "1", text: "A unique 6-character class code will be generated")
                        InfoStep(number: "2", text: "Share this code with your students")
                        InfoStep(number: "3", text: "View their progress on your dashboard")
                    }
                }
                .padding(PlantSpacing.lg)
                .background(Color.teacherBlue.opacity(0.05))
                .cornerRadius(PlantRadius.md)

                // Error Message
                if !errorMessage.isEmpty {
                    HStack(spacing: PlantSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.botanicalError)

                        Text(errorMessage)
                            .font(.bodySmall)
                            .foregroundColor(.botanicalError)

                        Spacer()
                    }
                    .padding(PlantSpacing.md)
                    .background(Color.botanicalError.opacity(0.1))
                    .cornerRadius(PlantRadius.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: PlantSpacing.xxl)

                // Login Button
                Button(action: handleLogin) {
                    HStack(spacing: PlantSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isNewTeacher ? "Create Classroom" : "Sign In")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PlantSpacing.lg)
                    .background(isFormValid && !isLoading ? Color.teacherBlue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .font(.titleSmall)
                    .cornerRadius(PlantRadius.md)
                    .shadow(
                        color: isFormValid ? Color.teacherBlue.opacity(0.3) : Color.clear,
                        radius: 12, x: 0, y: 6
                    )
                }
                .disabled(!isFormValid || isLoading)
            }
            .padding(.horizontal, PlantSpacing.xl)
            .padding(.bottom, PlantSpacing.xxl)
        }
        .background(Color.pageBackground)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.teacherBlue)
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFieldFocused = false }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    private func handleLogin() {
        isFieldFocused = false
        isLoading = true
        errorMessage = ""

        Task {
            do {
                try await teacherAuth.authenticateTeacher(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password,
                    isNewUser: isNewTeacher
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct InfoStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: PlantSpacing.md) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.teacherBlue)
                .clipShape(Circle())

            Text(text)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    NavigationView {
        TeacherLoginView()
            .environmentObject(TeacherAuthService())
    }
}
