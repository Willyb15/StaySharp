import SwiftUI

struct PracticeTimerView: View {
    @State private var elapsed: TimeInterval = 0
    @State private var goalSeconds: TimeInterval = 1800
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var showGoalPicker = false
    @State private var showHistory = false
    @ObservedObject private var log = PracticeLog.shared

    private let goals: [TimeInterval] = [300, 600, 900, 1800, 2700, 3600, 5400, 7200]
    private let minSaveThreshold: TimeInterval = 30

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image("StaySharpLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())

                Spacer()

                streakBadge
            }
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
        .sheet(isPresented: $showHistory) {
            PracticeHistoryView()
        }
    }

    // MARK: - Subviews

    private var streakBadge: some View {
        Button {
            showHistory = true
        } label: {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(log.streak)")
                        .font(.title3.weight(.bold))
                }
                Text("day streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

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
                if elapsed >= goalSeconds {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
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
                if elapsed >= minSaveThreshold {
                    log.add(duration: elapsed, goal: goalSeconds)
                }
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
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Goal Picker

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

// MARK: - History View

struct PracticeHistoryView: View {
    @ObservedObject private var log = PracticeLog.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.06).ignoresSafeArea()

                if log.sessions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No sessions yet")
                            .foregroundStyle(.secondary)
                        Text("Complete a session (30s min) to see it here")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        statsHeader
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())

                        ForEach(log.sessions) { session in
                            SessionRow(session: session)
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Practice History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statCell(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(log.streak)",
                label: "Day Streak"
            )
            Divider().frame(height: 40).background(Color.white.opacity(0.1))
            statCell(
                icon: "clock.fill",
                iconColor: .blue,
                value: "\(log.totalMinutes)",
                label: "Total Min"
            )
            Divider().frame(height: 40).background(Color.white.opacity(0.1))
            statCell(
                icon: "music.note",
                iconColor: .green,
                value: "\(log.sessions.count)",
                label: "Sessions"
            )
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .padding(.bottom, 8)
    }

    private func statCell(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(iconColor)
            Text(value).font(.title2.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionRow: View {
    let session: PracticeSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel)
                    .font(.subheadline.weight(.medium))
                Text(timeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(session.duration))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                if session.goalMet {
                    Label("Goal met", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var dateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(session.date) { return "Today" }
        if cal.isDateInYesterday(session.date) { return "Yesterday" }
        return session.date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var timeLabel: String {
        session.date.formatted(.dateTime.hour().minute())
    }

    private func formatDuration(_ s: TimeInterval) -> String {
        let h = Int(s) / 3600
        let m = (Int(s) % 3600) / 60
        let sec = Int(s) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}

#Preview {
    ZStack {
        Color(white: 0.06).ignoresSafeArea()
        PracticeTimerView()
    }
}
