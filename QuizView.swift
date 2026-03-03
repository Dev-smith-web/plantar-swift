import SwiftUI

struct QuizView: View {
    let plant: Plant
    let onComplete: (Float) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswerIndex: Int? = nil
    @State private var hasAnswered = false
    @State private var correctCount = 0
    @State private var showResults = false

    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < plant.quizQuestions.count else { return nil }
        return plant.quizQuestions[currentQuestionIndex]
    }

    private var progress: CGFloat {
        guard !plant.quizQuestions.isEmpty else { return 0 }
        return CGFloat(currentQuestionIndex) / CGFloat(plant.quizQuestions.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            quizHeader

            if showResults {
                QuizResultsView(
                    plant: plant,
                    correctCount: correctCount,
                    totalCount: plant.quizQuestions.count,
                    onRetake: retakeQuiz,
                    onDone: {
                        let score = Float(correctCount) / Float(plant.quizQuestions.count)
                        onComplete(score)
                        dismiss()
                    }
                )
            } else if let question = currentQuestion {
                ScrollView {
                    VStack(spacing: PlantSpacing.xl) {
                        // Progress indicator
                        progressBar

                        // Question card
                        QuizQuestionCard(
                            question: question,
                            questionNumber: currentQuestionIndex + 1,
                            totalQuestions: plant.quizQuestions.count,
                            selectedIndex: selectedAnswerIndex,
                            hasAnswered: hasAnswered,
                            onSelectAnswer: selectAnswer
                        )

                        // Explanation (shown after answering)
                        if hasAnswered {
                            explanationCard(question: question)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(PlantSpacing.lg)
                }

                // Bottom action button
                bottomButton
            } else {
                emptyState
            }
        }
        .background(Color.pageBackground)
    }

    // MARK: - Components

    private var quizHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.cardBackground)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Quiz")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                Text(plant.commonName)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, PlantSpacing.lg)
        .padding(.vertical, PlantSpacing.md)
        .background(Color(UIColor.systemBackground))
    }

    private var progressBar: some View {
        VStack(spacing: PlantSpacing.sm) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.plantPrimary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.plantPrimary)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("Question \(currentQuestionIndex + 1) of \(plant.quizQuestions.count)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(correctCount) correct")
                    .font(.caption)
                    .foregroundColor(.botanicalSuccess)
            }
        }
    }

    private func explanationCard(question: QuizQuestion) -> some View {
        let isCorrect = selectedAnswerIndex == question.correctAnswerIndex

        return VStack(alignment: .leading, spacing: PlantSpacing.md) {
            HStack(spacing: PlantSpacing.sm) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isCorrect ? .botanicalSuccess : .botanicalError)

                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.titleMedium)
                    .foregroundColor(isCorrect ? .botanicalSuccess : .botanicalError)
            }

            Text(question.explanation)
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(PlantSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: PlantRadius.md)
                .fill(isCorrect ? Color.botanicalSuccess.opacity(0.08) : Color.botanicalError.opacity(0.08))
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: handleNextAction) {
                Text(hasAnswered ? (isLastQuestion ? "See Results" : "Next Question") : "Select an answer")
            }
            .buttonStyle(PlantPrimaryButtonStyle(isEnabled: hasAnswered))
            .disabled(!hasAnswered)
            .padding(PlantSpacing.lg)
        }
        .background(Color(UIColor.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: PlantSpacing.lg) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)

            Text("No quiz questions available")
                .font(.titleMedium)
                .foregroundColor(.textSecondary)

            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(PlantSecondaryButtonStyle())
            .padding(.horizontal, PlantSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var isLastQuestion: Bool {
        currentQuestionIndex >= plant.quizQuestions.count - 1
    }

    private func selectAnswer(_ index: Int) {
        guard !hasAnswered else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedAnswerIndex = index
            hasAnswered = true

            if let question = currentQuestion, index == question.correctAnswerIndex {
                correctCount += 1
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        if selectedAnswerIndex == currentQuestion?.correctAnswerIndex {
            generator.notificationOccurred(.success)
        } else {
            generator.notificationOccurred(.error)
        }
    }

    private func handleNextAction() {
        if isLastQuestion {
            withAnimation {
                showResults = true
            }
        } else {
            withAnimation {
                currentQuestionIndex += 1
                selectedAnswerIndex = nil
                hasAnswered = false
            }
        }
    }

    private func retakeQuiz() {
        withAnimation {
            currentQuestionIndex = 0
            selectedAnswerIndex = nil
            hasAnswered = false
            correctCount = 0
            showResults = false
        }
    }
}

#Preview {
    QuizView(
        plant: plantDatabase[0],
        onComplete: { score in print("Score: \(score)") }
    )
}
