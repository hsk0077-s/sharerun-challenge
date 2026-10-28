import Foundation

struct WatchPendingRun: Codable, Identifiable, Equatable {
    let activityId: String
    let distanceKm: Double
    let durationSeconds: Int
    let heartRates: [Int]
    let startedAtIso: String
    let endedAtIso: String
    let totalSteps: Int

    var id: String { activityId }

    func toValidateRunBody() -> [String: Any] {
        var body: [String: Any] = [
            "activity_id": activityId,
            "distance_km": (distanceKm * 1000).rounded() / 1000,
            "duration_seconds": durationSeconds,
            "heart_rates": Array(heartRates.prefix(50000)),
            "cadence_spm": [Int](),
            "gyro_stability_score": 0.5,
            "gps_route": [[String: Any]](),
            "pace_samples": [[String: Any]](),
            "started_at": startedAtIso,
            "ended_at": endedAtIso,
            "device_info": [
                "watch_used": true,
                "heart_rate_used": !heartRates.isEmpty
            ]
        ]
        if totalSteps > 0 {
            body["total_steps"] = totalSteps
        }
        return body
    }
}

struct WatchPendingSteps: Codable, Equatable {
    let dayKey: String
    let steps: Int

    func toDailyStepsBody() -> [String: Any] {
        [
            "day_key": dayKey,
            "steps": min(30_000, steps),
            "source": "sensor"
        ]
    }
}

/// Persistent offline sync queue (up to 50 runs + latest daily steps) for Apple Watch.
@MainActor
final class WatchSyncQueue: ObservableObject {
    @Published private(set) var runs: [WatchPendingRun] = []
    @Published private(set) var pendingSteps: WatchPendingSteps?

    private let maxRuns = 50
    private let storageKey = "sharerun.watchos.sync_queue.v1"
    private let stepsStorageKey = "sharerun.watchos.pending_steps.v1"
    private let defaults = UserDefaults.standard

    var pendingCount: Int { runs.count }

    init() {
        load()
    }

    func enqueueRun(_ run: WatchPendingRun) {
        guard run.distanceKm > 0, run.durationSeconds > 0 else { return }
        guard !runs.contains(where: { $0.activityId == run.activityId }) else { return }
        runs.append(run)
        if runs.count > maxRuns {
            runs.removeFirst(runs.count - maxRuns)
        }
        save()
    }

    func enqueueSteps(dayKey: String, steps: Int) {
        guard steps > 0 else { return }
        pendingSteps = WatchPendingSteps(dayKey: dayKey, steps: steps)
        if let encoded = try? JSONEncoder().encode(pendingSteps) {
            defaults.set(encoded, forKey: stepsStorageKey)
        }
    }

    func acknowledge(activityId: String) {
        runs.removeAll { $0.activityId == activityId }
        save()
    }

    /// Uploads queued runs (`POST /actions/runs/validate`) and daily steps (`POST /actions/daily-steps`).
    func flush(using account: WatchAccountManager) async {
        guard account.isPaired else { return }

        for run in runs {
            guard let (status, _) = await account.postSigned(
                path: "/actions/runs/validate",
                payload: run.toValidateRunBody()
            ) else {
                break
            }
            if (200..<300).contains(status) || [400, 409, 413, 422].contains(status) {
                acknowledge(activityId: run.activityId)
            } else {
                break
            }
        }

        if let steps = pendingSteps {
            if let (status, _) = await account.postSigned(
                path: "/actions/daily-steps",
                payload: steps.toDailyStepsBody()
            ), (200..<300).contains(status) || [400, 409, 422].contains(status) {
                pendingSteps = nil
                defaults.removeObject(forKey: stepsStorageKey)
            }
        }
    }

    private func load() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([WatchPendingRun].self, from: data) {
            runs = decoded
        }
        if let stepData = defaults.data(forKey: stepsStorageKey),
           let decodedSteps = try? JSONDecoder().decode(WatchPendingSteps.self, from: stepData) {
            pendingSteps = decodedSteps
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(runs) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
