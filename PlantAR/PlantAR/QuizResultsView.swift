import SwiftUI

struct QuizResultsView: View {
    let plant: Plant
    let correctCount: Int
    let totalCount: Int
    let onRetake: () -> Void
    let onDone: () -> Void

    private var scorePercentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Float(correctCount) / Float(totalCount)) * 100)
    }

    private var isMastered: Bool {
        scorePercentage >= 80
    }

    private var resultMessage: String {
        switch scorePercentage {
        case 100:
            return "Perfect Score!"
        case 80...99:
            return "Excellent Work!"
        case 60...79:
            return "Good Effort!"
        case 40...59:
            return "Keep Learning!"
        default:
            return "Try Again!"
        }
    }

    private var resultDescription: String {
        if isMastered {
            return "You've mastered the basics of \(plant.commonName). Keep exploring to learn even more!"
        } else {
            return "Review the plant information and try the quiz again to improve your score."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PlantSpacing.xxl) {
                Spacer(minLength: PlantSpacing.xl)

                // Score circle
                scoreCircle

                // Result message
                VStack(spacing: PlantSpacing.sm) {
                    Text(resultMessage)
                        .font(.displayMedium)
                        .foregroundColor(.textPrimary)

                    Text(resultDescription)
                        .font(.bodyMedium)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, PlantSpacing.lg)
                }

                // Mastery badge (if earned)
                if isMastered {
                    masteryBadge
                }

                // Stats breakdown
                statsCard

                Spacer(minLength: PlantSpacing.xl)

                // Action buttons
                VStack(spacing: PlantSpacing.md) {
                    Button("Done") {
                        onDone()
                    }
                    .buttonStyle(PlantPrimaryButtonStyle())

                    if !isMastered {
                        Button("Try Again") {
                            onRetake()
                        }
                        .buttonStyle(PlantSecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, PlantSpacing.lg)
                .padding(.bottom, PlantSpacing.xl)
            }
        }
        .background(Color.pageBackground)
    }

    // MARK: - Components

    private var scoreCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.plantPrimary.opacity(0.2), lineWidth: 12)
                .frame(width: 160, height: 160)

            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(scorePercentage) / 100)
                .stroke(
                    isMastered ? Color.botanicalSuccess : Color.plantPrimary,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: scorePercentage)

            // Score text
            VStack(spacing: 0) {
                Text("\(scorePercentage)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(isMastered ? .botanicalSuccess : .plantPrimary)

                Text("%")
                    .font(.titleMedium)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var masteryBadge: some View {
        HStack(spacing: PlantSpacing.md) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.botanicalSuccess)

            VStack(alignment: .leading, spacing: 2) {
                Text("Plant Mastery Achieved")
                    .font(.titleSmall)
                    .foregroundColor(.botanicalSuccess)

                Text("\(plant.commonName) added to your mastered plants")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(PlantSpacing.lg)
        .background(Color.botanicalSuccess.opacity(0.1))
        .cornerRadius(PlantRadius.md)
        .padding(.horizontal, PlantSpacing.lg)
    }

    private var statsCard: some View {
        VStack(spacing: PlantSpacing.lg) {
            Text("Quiz Summary")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: PlantSpacing.lg) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    iconColor: .botanicalSuccess,
                    value: "\(correctCount)",
                    label: "Correct"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    icon: "xmark.circle.fill",
                    iconColor: .botanicalError,
                    value: "\(totalCount - correctCount)",
                    label: "Incorrect"
                )

                Divider()
                    .frame(height: 40)

                StatItem(
                    icon: "number.circle.fill",
                    iconColor: .botanicalInfo,
                    value: "\(totalCount)",
                    label: "Total"
                )
            }
        }
        .padding(PlantSpacing.xl)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.lg)
        .padding(.horizontal, PlantSpacing.lg)
    }
}

struct StatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: PlantSpacing.sm) {
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
    }
}

#Preview {
    QuizResultsView(
        plant: plantDatabase[0],
        correctCount: 3,
        totalCount: 4,
        onRetake: {},
        onDone: {}
    )
}

#Preview("Low Score") {
    QuizResultsView(
        plant: plantDatabase[0],
        correctCount: 1,
        totalCount: 4,
        onRetake: {},
        onDone: {}
    )
}
