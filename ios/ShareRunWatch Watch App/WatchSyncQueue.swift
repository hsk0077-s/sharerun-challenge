import Foundation

struct WatchRoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let recordedAt: String

    func toJson() -> [String: Any] {
        ["latitude": latitude, "longitude": longitude, "recordedAt": recordedAt]
    }
}

struct WatchPaceSample: Codable, Equatable {
    let secondsPerKm: Int
    let recordedAt: String

    func toJson() -> [String: Any] {
        // PaceSamplePayload.secondsPerKm is 0...7200. A slower sample would
        // 422 the whole run, and the queue treats 422 as final.
        let pace = min(7200, max(0, secondsPerKm))
        return ["secondsPerKm": pace, "recordedAt": recordedAt]
    }
}

struct WatchPendingRun: Codable, Identifiable, Equatable {
    let activityId: String
    let distanceKm: Double
    let durationSeconds: Int
    let heartRates: [Int]
    let startedAtIso: String
    let endedAtIso: String
    let totalSteps: Int
    let gpsRoute: [WatchRoutePoint]
    let paceSamples: [WatchPaceSample]

    var id: String { activityId }

    init(
        activityId: String,
        distanceKm: Double,
        durationSeconds: Int,
        heartRates: [Int],
        startedAtIso: String,
        endedAtIso: String,
        totalSteps: Int,
        gpsRoute: [WatchRoutePoint] = [],
        paceSamples: [WatchPaceSample] = []
    ) {
        self.activityId = activityId
        self.distanceKm = distanceKm
        self.durationSeconds = durationSeconds
        self.heartRates = heartRates
        self.startedAtIso = startedAtIso
        self.endedAtIso = endedAtIso
        self.totalSteps = totalSteps
        self.gpsRoute = gpsRoute
        self.paceSamples = paceSamples
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityId = try container.decode(String.self, forKey: .activityId)
        distanceKm = try container.decode(Double.self, forKey: .distanceKm)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        heartRates = try container.decode([Int].self, forKey: .heartRates)
        startedAtIso = try container.decode(String.self, forKey: .startedAtIso)
        endedAtIso = try container.decode(String.self, forKey: .endedAtIso)
        totalSteps = try container.decode(Int.self, forKey: .totalSteps)
        gpsRoute = try container.decodeIfPresent([WatchRoutePoint].self, forKey: .gpsRoute) ?? []
        paceSamples = try container.decodeIfPresent([WatchPaceSample].self, forKey: .paceSamples) ?? []
    }

    func toValidateRunBody(deviceId: String? = nil) -> [String: Any] {
        var body: [String: Any] = [
            "activity_id": activityId,
            "distance_km": (distanceKm * 1000).rounded() / 1000,
            "duration_seconds": durationSeconds,
            "heart_rates": Array(heartRates.prefix(50000)),
            "cadence_spm": [Int](),
            "gyro_stability_score": 0.5,
            "gps_route": gpsRoute.suffix(400).map { $0.toJson() },
            "pace_samples": paceSamples.suffix(2000).map { $0.toJson() },
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
        // Same field as ValidateRunRequest.device_id. Empty is omitted so a
        // missing id is not stored as a blank string.
        if let deviceId, !deviceId.isEmpty {
            body["device_id"] = deviceId
        }
        return body
    }
}

struct WatchPendingSteps: Codable, Equatable {
    let dayKey: String
    let steps: Int

    func toDailyStepsBody() -> [String: Any] {
        // DailyStepsRequest.source is only health_connect or sensor.
        // steps is 1...30000. A larger total is a 422, which this queue drops.
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
    private var flushGate = WatchFlushGate()

    var pendingCount: Int { runs.count }

    /// False when a flush is already in progress. Wear OS calls this `tryBeginFlush`.
    func tryBeginFlush() -> Bool {
        flushGate.tryBegin()
    }

    func endFlush() {
        flushGate.end()
    }

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
        guard tryBeginFlush() else { return }
        defer { endFlush() }

        for run in runs {
            guard let (status, _) = await account.postSigned(
                path: "/actions/runs/validate",
                payload: run.toValidateRunBody(deviceId: account.deviceId())
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
