import SwiftUI

// MARK: - Parental Gate

struct ParentalGate: View {
    let onSuccess: () -> Void
    let onDismiss: () -> Void

    @State private var answer: String = ""
    @State private var showError = false
    @State private var problem = MathProblem.generate()

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Parent Verification")
                    .font(.title2.bold())

                Text("Please solve this math problem")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Math problem
            VStack(spacing: 16) {
                Text(problem.question)
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                TextField("Answer", text: $answer)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(width: 120)

                if showError {
                    Text("Incorrect, try again")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )

            // Buttons
            VStack(spacing: 12) {
                Button {
                    verifyAnswer()
                } label: {
                    Text("Verify")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        )
        .padding(.horizontal, 24)
    }

    private func verifyAnswer() {
        if let userAnswer = Int(answer), userAnswer == problem.answer {
            onSuccess()
        } else {
            showError = true
            answer = ""
            // Generate new problem after failure
            problem = MathProblem.generate()
        }
    }
}

// MARK: - Math Problem

struct MathProblem {
    let question: String
    let answer: Int

    static func generate() -> MathProblem {
        let operations = ["+", "-", "×"]
        let operation = operations.randomElement()!

        let a: Int
        let b: Int
        let answer: Int

        switch operation {
        case "+":
            a = Int.random(in: 10...50)
            b = Int.random(in: 10...50)
            answer = a + b
        case "-":
            a = Int.random(in: 20...50)
            b = Int.random(in: 5...a-5)
            answer = a - b
        case "×":
            a = Int.random(in: 3...12)
            b = Int.random(in: 3...12)
            answer = a * b
        default:
            a = 0
            b = 0
            answer = 0
        }

        return MathProblem(
            question: "\(a) \(operation) \(b) = ?",
            answer: answer
        )
    }
}

// MARK: - Parental Gate Sheet Modifier

struct ParentalGateModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void

    @State private var showGate = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { newValue in
                if newValue {
                    showGate = true
                }
            }
            .sheet(isPresented: $showGate) {
                ParentalGate(
                    onSuccess: {
                        showGate = false
                        isPresented = false
                        onSuccess()
                    },
                    onDismiss: {
                        showGate = false
                        isPresented = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func parentalGate(isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> some View {
        modifier(ParentalGateModifier(isPresented: isPresented, onSuccess: onSuccess))
    }
}

// MARK: - Preview

#Preview("Parental Gate") {
    ZStack {
        Color.black.opacity(0.3)
        ParentalGate(
            onSuccess: { },
            onDismiss: { }
        )
    }
}
