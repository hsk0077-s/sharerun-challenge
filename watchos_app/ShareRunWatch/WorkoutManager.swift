import CoreLocation
import Foundation
import HealthKit

enum WatchRunPhase: Equatable {
    case start
    case pairing
    case running
    case paused
    case rankAlert(rank: Int, gapPeople: Int)
    case summary
}

/// Real-time Apple Watch workout engine using `HKWorkoutSession` + `HKLiveWorkoutBuilder` + `CLLocationManager`.
@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    @Published var phase: WatchRunPhase = .start
    @Published var targetKm: Double = 3.0
    @Published private(set) var distanceKm: Double = 0.0
    @Published private(set) var movingSeconds: Int = 0
    @Published private(set) var lastHeartRate: Int = 0
    @Published private(set) var totalSteps: Int = 0
    @Published private(set) var cadenceSpm: Int = 0

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var liveBuilder: HKLiveWorkoutBuilder?
    private let locationManager = CLLocationManager()

    private var timer: Timer?
    private var startedAt: Date?
    private var lastLocation: CLLocation?
    private var heartRateSamples: [Int] = []
    private var currentActivityId: String = ""

    var paceSecondsPerKm: Int {
        guard distanceKm >= 0.01, movingSeconds > 0 else { return 0 }
        return Int((Double(movingSeconds) / distanceKm).rounded())
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
    }

    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        locationManager.requestWhenInUseAuthorization()
        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            return true
        } catch {
            return false
        }
    }

    func startRun() async {
        _ = await requestAuthorization()
        distanceKm = 0.0
        movingSeconds = 0
        lastHeartRate = 0
        totalSteps = 0
        cadenceSpm = 0
        heartRateSamples.removeAll()
        lastLocation = nil
        startedAt = Date()
        currentActivityId = "watchos-\(Int(Date().timeIntervalSince1970 * 1000))"

        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )
            session.delegate = self
            builder.delegate = self
            self.workoutSession = session
            self.liveBuilder = builder

            let now = Date()
            session.startActivity(with: now)
            try await builder.beginCollection(at: now)
        } catch {
            // Continues with GPS + timer fallback in simulator.
        }

        locationManager.startUpdatingLocation()
        startTicker()
        phase = .running
    }

    func pauseRun() {
        guard phase == .running else { return }
        workoutSession?.pause()
        locationManager.stopUpdatingLocation()
        stopTicker()
        phase = .paused
    }

    func resumeRun() {
        guard phase == .paused else { return }
        workoutSession?.resume()
        locationManager.startUpdatingLocation()
        startTicker()
        phase = .running
    }

    func showRankAlert(rank: Int, gapPeople: Int) {
        guard phase == .running else { return }
        phase = .rankAlert(rank: rank, gapPeople: gapPeople)
    }

    func dismissRankAlert() {
        if case .rankAlert = phase {
            phase = .running
        }
    }

    func finishRun(into queue: WatchSyncQueue, account: WatchAccountManager) async {
        stopTicker()
        locationManager.stopUpdatingLocation()
        let end = Date()
        let start = startedAt ?? end

        workoutSession?.end()
        if let builder = liveBuilder {
            try? await builder.endCollection(at: end)
            _ = try? await builder.finishWorkout()
        }
        workoutSession = nil
        liveBuilder = nil

        if distanceKm > 0 && movingSeconds > 0 {
            let iso = ISO8601DateFormatter()
            let pending = WatchPendingRun(
                activityId: currentActivityId,
                distanceKm: distanceKm,
                durationSeconds: movingSeconds,
                heartRates: heartRateSamples,
                startedAtIso: iso.string(from: start),
                endedAtIso: iso.string(from: end),
                totalSteps: totalSteps
            )
            queue.enqueueRun(pending)
            if totalSteps > 0 {
                let dayKey = Self.kstDayKey(for: end)
                queue.enqueueSteps(dayKey: dayKey, steps: totalSteps)
            }
            await queue.flush(using: account)
        }
        phase = .summary
    }

    func resetToStart() {
        phase = .start
    }

    private func startTicker() {
        stopTicker()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.phase == .running else { return }
                self.movingSeconds += 1
                if self.movingSeconds > 0 && self.totalSteps > 0 {
                    let minutes = Double(self.movingSeconds) / 60.0
                    self.cadenceSpm = min(250, Int((Double(self.totalSteps) / minutes).rounded()))
                }
            }
        }
    }

    private func stopTicker() {
        timer?.invalidate()
        timer = nil
    }

    private static func kstDayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {}

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            guard let statistics = workoutBuilder.statistics(for: quantityType) else { continue }

            Task { @MainActor in
                switch quantityType {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    if let bpm = statistics.mostRecentQuantity()?.doubleValue(for: unit) {
                        let rounded = Int(bpm.rounded())
                        if (30...230).contains(rounded) {
                            self.lastHeartRate = rounded
                            self.heartRateSamples.append(rounded)
                        }
                    }
                case HKQuantityType.quantityType(forIdentifier: .stepCount):
                    if let steps = statistics.sumQuantity()?.doubleValue(for: .count()) {
                        self.totalSteps = max(0, Int(steps.rounded()))
                    }
                case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                    if let meters = statistics.sumQuantity()?.doubleValue(for: .meter()) {
                        let hkKm = meters / 1000.0
                        if hkKm > self.distanceKm {
                            self.distanceKm = hkKm
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}

extension WorkoutManager: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            guard self.phase == .running else { return }
            for loc in locations where loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy <= 35 {
                if let prev = self.lastLocation {
                    let delta = loc.distance(from: prev)
                    if delta > 0.5 && delta < 100 {
                        self.distanceKm += delta / 1000.0
                    }
                }
                self.lastLocation = loc
            }
        }
    }
}
