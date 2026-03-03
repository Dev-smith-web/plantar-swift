import SwiftUI

// MARK: - PlantAR Design System

// MARK: - Color Palette

extension Color {
    // Primary Brand Colors (Green for actions)
    static let plantPrimary = Color(red: 0.13, green: 0.55, blue: 0.13)
    static let plantPrimaryDark = Color(red: 0.10, green: 0.42, blue: 0.10)
    static let plantPrimaryLight = Color(red: 0.56, green: 0.93, blue: 0.56)

    // Earth Tones (Secondary palette)
    static let earthBrown = Color(red: 0.55, green: 0.27, blue: 0.07)
    static let earthTan = Color(red: 0.82, green: 0.71, blue: 0.55)
    static let leafOlive = Color(red: 0.42, green: 0.56, blue: 0.14)
    static let barkDark = Color(red: 0.24, green: 0.15, blue: 0.10)

    // Backgrounds
    static let naturalCream = Color(red: 0.98, green: 0.97, blue: 0.94)
    static let softWhite = Color(red: 0.99, green: 0.99, blue: 0.98)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let pageBackground = Color(UIColor.systemGroupedBackground)

    // Semantic Colors
    static let botanicalSuccess = Color(red: 0.18, green: 0.65, blue: 0.20)
    static let botanicalError = Color(red: 0.80, green: 0.22, blue: 0.22)
    static let botanicalWarning = Color(red: 0.90, green: 0.62, blue: 0.15)
    static let botanicalInfo = Color(red: 0.20, green: 0.50, blue: 0.75)

    // Teacher Portal (Blue accent)
    static let teacherBlue = Color(red: 0.20, green: 0.45, blue: 0.80)
    static let teacherBlueLight = Color(red: 0.40, green: 0.65, blue: 0.95)

    // Text Colors
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
}

// MARK: - Typography

extension Font {
    // Display - For large headers and hero text
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .serif)
    static let displayMedium = Font.system(size: 28, weight: .semibold, design: .serif)
    static let displaySmall = Font.system(size: 24, weight: .semibold, design: .serif)

    // Title - For section headers
    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .rounded)

    // Body - For content
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .rounded)

    // Labels & Captions
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .rounded)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 11, weight: .regular, design: .rounded)

    // Scientific Names (Italic serif)
    static let scientific = Font.system(size: 15, weight: .regular, design: .serif).italic()
    static let scientificSmall = Font.system(size: 13, weight: .regular, design: .serif).italic()
}

// MARK: - Spacing Constants

struct PlantSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

struct PlantRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}

// MARK: - Shadow Styles

struct PlantShadow {
    static let light = (color: Color.black.opacity(0.05), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
    static let medium = (color: Color.black.opacity(0.10), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
    static let heavy = (color: Color.black.opacity(0.15), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))
}

// MARK: - Button Styles

struct PlantPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.titleMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlantSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: PlantRadius.md)
                    .fill(isEnabled ? Color.plantPrimary : Color.gray.opacity(0.3))
            )
            .shadow(
                color: isEnabled ? Color.plantPrimary.opacity(0.3) : Color.clear,
                radius: 8, x: 0, y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PlantSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.titleMedium)
            .foregroundColor(.plantPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlantSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: PlantRadius.md)
                    .fill(Color.plantPrimary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: PlantRadius.md)
                    .stroke(Color.plantPrimary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PlantGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.labelLarge)
            .foregroundColor(.plantPrimary)
            .padding(.horizontal, PlantSpacing.lg)
            .padding(.vertical, PlantSpacing.sm)
            .background(configuration.isPressed ? Color.plantPrimary.opacity(0.1) : Color.clear)
            .cornerRadius(PlantRadius.sm)
    }
}

// MARK: - Card Modifier

struct PlantCardModifier: ViewModifier {
    var padding: CGFloat = PlantSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBackground)
            .cornerRadius(PlantRadius.lg)
            .shadow(
                color: PlantShadow.light.color,
                radius: PlantShadow.light.radius,
                x: PlantShadow.light.x,
                y: PlantShadow.light.y
            )
    }
}

extension View {
    func plantCard(padding: CGFloat = PlantSpacing.lg) -> some View {
        modifier(PlantCardModifier(padding: padding))
    }
}

// MARK: - Icon Button Style

struct PlantIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    var backgroundColor: Color = .plantPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Quiz Option Button Style

struct QuizOptionButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    var isCorrect: Bool? = nil // nil = not revealed, true = correct, false = incorrect

    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? Color.botanicalSuccess.opacity(0.15) : Color.botanicalError.opacity(0.15)
        }
        return isSelected ? Color.plantPrimary.opacity(0.1) : Color.cardBackground
    }

    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? Color.botanicalSuccess : Color.botanicalError
        }
        return isSelected ? Color.plantPrimary : Color.clear
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyLarge)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(PlantSpacing.lg)
            .background(backgroundColor)
            .cornerRadius(PlantRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: PlantRadius.md)
                    .stroke(borderColor, lineWidth: isSelected || isCorrect != nil ? 2 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Tab Bar Appearance

struct PlantTabStyle {
    static func configure() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Color.plantPrimary)
    }
}

// MARK: - Navigation Bar Appearance

struct PlantNavigationStyle {
    static func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.serif)!, size: 34),
            .foregroundColor: UIColor.label
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.plantPrimary)
    }
}

// MARK: - Preview Helpers

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Button") {}
            .buttonStyle(PlantPrimaryButtonStyle())

        Button("Secondary Button") {}
            .buttonStyle(PlantSecondaryButtonStyle())

        Button("Ghost Button") {}
            .buttonStyle(PlantGhostButtonStyle())
    }
    .padding()
}

#Preview("Colors") {
    VStack(spacing: 8) {
        HStack {
            Color.plantPrimary.frame(height: 50)
            Color.plantPrimaryDark.frame(height: 50)
            Color.plantPrimaryLight.frame(height: 50)
        }
        HStack {
            Color.earthBrown.frame(height: 50)
            Color.earthTan.frame(height: 50)
            Color.leafOlive.frame(height: 50)
        }
        HStack {
            Color.botanicalSuccess.frame(height: 50)
            Color.botanicalError.frame(height: 50)
            Color.botanicalWarning.frame(height: 50)
        }
    }
    .padding()
}
