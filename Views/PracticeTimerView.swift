import SwiftUI

struct PracticeTimerView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var goalSeconds: TimeInterval = 1800  // 30 min default
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var showGoalPicker = false

    private let goals: [TimeInterval] = [300, 600, 900, 1800, 2700, 3600, 5400, 7200]

    var body: some View {
        VStack(spacing: 0) {
            Image("StringSenseLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .padding(.top, 16)

            Spacer()

            progressRing

            Spacer()

            elapsedLabel

            goalLabel

            Spacer()

            controlRow

            Spacer(minLength: 40)
        }
        .padding(.horizontal)
        .sheet(isPresented: $showGoalPicker) {
            GoalPickerView(goals: goals, selected: $goalSeconds)
        }
    }

    // MARK: - Subviews

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 12)

            Circle()
                .trim(from: 0, to: CGFloat(min(elapsed / goalSeconds, 1.0)))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: elapsed)

            VStack(spacing: 4) {
                Text(formatTime(elapsed))
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 240, height: 240)
    }

    private var elapsedLabel: some View {
        Text(isRunning ? "Keep playing!" : elapsed > 0 ? "Paused" : "Ready when you are")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }

    private var goalLabel: some View {
        Button {
            showGoalPicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "target")
                Text("Goal: \(formatTime(goalSeconds))")
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .font(.subheadline)
            .foregroundStyle(elapsed >= goalSeconds ? .green : .secondary)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }

    private var controlRow: some View {
        HStack(spacing: 16) {
            Button {
                elapsed = 0
                stopTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(elapsed == 0 && !isRunning)
            .opacity(elapsed == 0 && !isRunning ? 0.3 : 1)

            Button {
                isRunning ? stopTimer() : startTimer()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                    Text(isRunning ? "Pause" : elapsed > 0 ? "Resume" : "Start")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isRunning ? Color.green.opacity(0.25) : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isRunning ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var progressColor: Color {
        let fraction = elapsed / goalSeconds
        if fraction >= 1.0 { return .green }
        if fraction >= 0.8 { return Color(hue: 0.25, saturation: 0.9, brightness: 1.0) }
        return Color(hue: 0.55, saturation: 0.8, brightness: 1.0)
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

struct GoalPickerView: View {
    let goals: [TimeInterval]
    @Binding var selected: TimeInterval
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(goals, id: \.self) { goal in
                    Button {
                        selected = goal
                        dismiss()
                    } label: {
                        HStack {
                            Text(label(for: goal))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selected == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.06))
            .navigationTitle("Practice Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func label(for seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let h = m / 60
        if h > 0 { return "\(h) hour\(h > 1 ? "s" : "")" }
        return "\(m) minutes"
    }
}

#Preview {
    ZStack {
        Color(white: 0.06).ignoresSafeArea()
        PracticeTimerView()
    }
}
