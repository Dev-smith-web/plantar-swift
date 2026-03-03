import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var isNewStudent = true
    @State private var name = ""
    @State private var email = ""
    @State private var classCode = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        let nameOK = isNewStudent ? !name.trimmingCharacters(in: .whitespaces).isEmpty : true
        let codeOK = isNewStudent ? classCode.count == 6 : true
        return nameOK && email.contains("@") && codeOK && password.count >= 6
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PlantSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: PlantSpacing.sm) {
                    Text("Welcome")
                        .font(.displayLarge)
                        .foregroundColor(.textPrimary)

                    Text("Sign in to start exploring plants in augmented reality and track your botanical discoveries.")
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, PlantSpacing.lg)

                // New / Returning toggle
                Picker("", selection: $isNewStudent) {
                    Text("New Student").tag(true)
                    Text("Returning Student").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: isNewStudent) { _, _ in errorMessage = "" }

                // Form Fields
                VStack(spacing: PlantSpacing.lg) {
                    if isNewStudent {
                        FormField(
                            title: "Your Name",
                            placeholder: "Enter your full name",
                            icon: "person.fill",
                            text: $name
                        )
                    }

                    FormField(
                        title: "Email",
                        placeholder: "your.email@school.edu",
                        icon: "envelope.fill",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    if isNewStudent {
                        FormField(
                            title: "Class Code",
                            placeholder: "6-digit code from teacher",
                            icon: "number",
                            text: $classCode,
                            autocapitalization: .characters,
                            characterLimit: 6
                        )
                    }

                    SecureFormField(
                        title: "Password",
                        placeholder: isNewStudent ? "Create a password" : "Enter your password",
                        text: $password
                    )
                }

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
                }

                Spacer(minLength: PlantSpacing.xxl)

                // Login Button
                Button(action: handleLogin) {
                    HStack(spacing: PlantSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Start Exploring")
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .buttonStyle(PlantPrimaryButtonStyle(isEnabled: isFormValid && !isLoading))
                .disabled(!isFormValid || isLoading)

                // Help text
                Text("Your class code is provided by your teacher. Contact them if you don't have one.")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PlantSpacing.lg)
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
                        .foregroundColor(.plantPrimary)
                }
            }
        }
    }

    private func handleLogin() {
        errorMessage = ""
        isLoading = true

        Task {
            do {
                try await auth.login(
                    email: email.trimmingCharacters(in: .whitespaces),
                    name: name.trimmingCharacters(in: .whitespaces),
                    classCode: classCode.uppercased(),
                    password: password,
                    isNewUser: isNewStudent
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Form Field Component

struct FormField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var characterLimit: Int? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PlantSpacing.sm) {
            Text(title)
                .font(.labelLarge)
                .foregroundColor(.textSecondary)

            HStack(spacing: PlantSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .plantPrimary : .textTertiary)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                    .textInputAutocapitalization(autocapitalization)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled(true)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        if let limit = characterLimit, newValue.count > limit {
                            text = String(newValue.prefix(limit))
                        }
                    }

                if !text.isEmpty {
                    Button(action: { text = "" }) {
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
                    .stroke(isFocused ? Color.plantPrimary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Secure Form Field Component

struct SecureFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: PlantSpacing.sm) {
            Text(title)
                .font(.labelLarge)
                .foregroundColor(.textSecondary)

            HStack(spacing: PlantSpacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? .plantPrimary : .textTertiary)
                    .frame(width: 20)

                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.bodyLarge)
                .foregroundColor(.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($isFocused)

                Button(action: { isVisible.toggle() }) {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(PlantSpacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(PlantRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: PlantRadius.md)
                    .stroke(isFocused ? Color.plantPrimary : Color.clear, lineWidth: 2)
            )

            Text("Minimum 6 characters. Use the same password each time.")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
    }
}

#Preview {
    NavigationView {
        LoginView()
            .environmentObject(AuthService())
    }
}
