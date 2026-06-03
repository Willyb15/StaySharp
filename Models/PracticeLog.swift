import Foundation
import Combine

struct PracticeSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let goalSeconds: TimeInterval

    var goalMet: Bool { duration >= goalSeconds }
}

class PracticeLog: ObservableObject {
    static let shared = PracticeLog()

    @Published private(set) var sessions: [PracticeSession] = []

    private let key = "staysharp_practice_sessions"

    init() { load() }

    func add(duration: TimeInterval, goal: TimeInterval) {
        let session = PracticeSession(id: UUID(), date: Date(), duration: duration, goalSeconds: goal)
        sessions.insert(session, at: 0)
        persist()
    }

    var streak: Int {
        let calendar = Calendar.current
        var checkDay = calendar.startOfDay(for: Date())
        var count = 0
        for _ in 0..<365 {
            let hasSession = sessions.contains { calendar.isDate($0.date, inSameDayAs: checkDay) }
            if !hasSession { break }
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }
        return count
    }

    var totalMinutes: Int {
        Int(sessions.reduce(0) { $0 + $1.duration }) / 60
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PracticeSession].self, from: data)
        else { return }
        sessions = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
