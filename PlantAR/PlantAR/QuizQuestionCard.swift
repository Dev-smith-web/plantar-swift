import SwiftUI

struct QuizQuestionCard: View {
    let question: QuizQuestion
    let questionNumber: Int
    let totalQuestions: Int
    let selectedIndex: Int?
    let hasAnswered: Bool
    let onSelectAnswer: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PlantSpacing.xl) {
            // Question text
            Text(question.question)
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Answer options
            VStack(spacing: PlantSpacing.md) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    AnswerOptionButton(
                        text: option,
                        index: index,
                        isSelected: selectedIndex == index,
                        isCorrect: hasAnswered ? index == question.correctAnswerIndex : nil,
                        showResult: hasAnswered,
                        onTap: {
                            onSelectAnswer(index)
                        }
                    )
                }
            }
        }
        .padding(PlantSpacing.xl)
        .background(Color.cardBackground)
        .cornerRadius(PlantRadius.lg)
    }
}

struct AnswerOptionButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool?
    let showResult: Bool
    let onTap: () -> Void

    private var optionLetter: String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return index < letters.count ? letters[index] : "\(index + 1)"
    }

    private var backgroundColor: Color {
        if showResult {
            if isCorrect == true {
                return Color.botanicalSuccess.opacity(0.12)
            } else if isSelected && isCorrect == false {
                return Color.botanicalError.opacity(0.12)
            }
        }
        return isSelected ? Color.plantPrimary.opacity(0.08) : Color(UIColor.tertiarySystemGroupedBackground)
    }

    private var borderColor: Color {
        if showResult {
            if isCorrect == true {
                return Color.botanicalSuccess
            } else if isSelected && isCorrect == false {
                return Color.botanicalError
            }
        }
        return isSelected ? Color.plantPrimary : Color.clear
    }

    private var letterBackgroundColor: Color {
        if showResult {
            if isCorrect == true {
                return Color.botanicalSuccess
            } else if isSelected && isCorrect == false {
                return Color.botanicalError
            }
        }
        return isSelected ? Color.plantPrimary : Color.textTertiary.opacity(0.3)
    }

    private var iconName: String? {
        guard showResult else { return nil }
        if isCorrect == true {
            return "checkmark"
        } else if isSelected && isCorrect == false {
            return "xmark"
        }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: PlantSpacing.md) {
                // Letter indicator or result icon
                ZStack {
                    Circle()
                        .fill(letterBackgroundColor)
                        .frame(width: 32, height: 32)

                    if let icon = iconName {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(optionLetter)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .textSecondary)
                    }
                }

                // Answer text
                Text(text)
                    .font(.bodyLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Selection indicator
                if isSelected && !showResult {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.plantPrimary)
                }
            }
            .padding(PlantSpacing.lg)
            .background(backgroundColor)
            .cornerRadius(PlantRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: PlantRadius.md)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(showResult)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: showResult)
    }
}

#Preview("Question Card") {
    VStack {
        QuizQuestionCard(
            question: QuizQuestion(
                id: "test",
                question: "What is the primary function of roots?",
                options: ["Absorb water", "Produce seeds", "Make leaves", "Store sunlight"],
                correctAnswerIndex: 0,
                explanation: "Roots absorb water and minerals from the soil."
            ),
            questionNumber: 1,
            totalQuestions: 4,
            selectedIndex: nil,
            hasAnswered: false,
            onSelectAnswer: { _ in }
        )

        QuizQuestionCard(
            question: QuizQuestion(
                id: "test2",
                question: "What is the primary function of roots?",
                options: ["Absorb water", "Produce seeds", "Make leaves", "Store sunlight"],
                correctAnswerIndex: 0,
                explanation: "Roots absorb water and minerals from the soil."
            ),
            questionNumber: 1,
            totalQuestions: 4,
            selectedIndex: 1,
            hasAnswered: true,
            onSelectAnswer: { _ in }
        )
    }
    .padding()
    .background(Color.pageBackground)
}
