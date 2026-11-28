import CoreLocation
import Foundation
import HealthKit
import WatchKit

enum WatchRunPhase: Equatable {
    case start
    case pairing
    /// 3·2·1 before the run starts (same as Wear OS `CountdownFace`).
    case countdown(Int)
    case running
    case paused
    /// Finish was pressed and the workout is being saved. Pause, resume and a
    /// second finish all do nothing here.
    case finishing
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
    /// Which number is big on the running face: 0 distance, 1 time, 2 pace.
    @Published var focus: Int = 0
    /// The km just passed, shown for a few seconds. Nil the rest of the time.
    @Published private(set) var bannerKm: Int?
    /// Route for the line page and the summary. At most 400 points.
    @Published private(set) var routePoints: [WatchRoutePoint] = []
    /// Id of the run that is running or just finished (for its server reward).
    @Published private(set) var lastActivityId: String?
    /// The finished run went into the upload queue (false for a zero-distance run,
    /// which hides the summary's reward line).
    @Published private(set) var lastRunQueued = false

    static let metricCount = 3

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var liveBuilder: HKLiveWorkoutBuilder?
    private let locationManager = CLLocationManager()

    private var timer: Timer?
    private var startedAt: Date?
    private var lastLocation: CLLocation?
    private var heartRateSamples: [Int] = []
    private var paceSamples: [WatchPaceSample] = []
    private var countdownTimer: Timer?
    private var wholeKm: Int = 0
    private var bannerUntil: Date?
    private var lastPaceKm: Double = 0
    private var currentActivityId: String = ""

    var paceSecondsPerKm: Int {
        guard distanceKm >= 0.01, movingSeconds > 0 else { return 0 }
        return Int((Double(movingSeconds) / distanceKm).rounded())
    }

    /// Progress toward the next whole km (0...1), like Wear OS `kmProgress`.
    var kmProgress: Double {
        guard distanceKm > 0, distanceKm.isFinite else { return 0 }
        return distanceKm - distanceKm.rounded(.down)
    }

    func cycleFocus() {
        focus = (focus + 1) % Self.metricCount
    }

    /// Start pressed: 3·2·1, a short tap each second, then the run starts.
    func beginCountdown() {
        guard phase == .start else { return }
        phase = .countdown(3)
        Self.buzz(.click)
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.countdownTick()
            }
        }
    }

    private func countdownTick() {
        guard case let .countdown(count) = phase else {
            countdownTimer?.invalidate()
            countdownTimer = nil
            return
        }
        if count <= 1 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            Task { await startRun() }
        } else {
            phase = .countdown(count - 1)
            Self.buzz(.click)
        }
    }

    func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        if case .countdown = phase { phase = .start }
    }

    static func buzz(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
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
        routePoints.removeAll()
        paceSamples.removeAll()
        lastPaceKm = 0
        lastLocation = nil
        wholeKm = 0
        bannerKm = nil
        bannerUntil = nil
        focus = 0
        startedAt = Date()
        currentActivityId = "watchos-\(Int(Date().timeIntervalSince1970 * 1000))"
        lastActivityId = currentActivityId

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

        // With the workout session running, keep GPS going when the wrist drops
        // or the screen turns off. Needs UIBackgroundModes `location` (Info.plist).
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startTicker()
        phase = .running
        Self.buzz(.start)
    }

    func pauseRun() {
        guard phase == .running else { return }
        workoutSession?.pause()
        locationManager.stopUpdatingLocation()
        stopTicker()
        phase = .paused
        Self.buzz(.click)
    }

    func resumeRun() {
        guard phase == .paused else { return }
        workoutSession?.resume()
        locationManager.startUpdatingLocation()
        startTicker()
        phase = .running
        Self.buzz(.click)
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
        // Only once. Leave running/paused first, before any await, so a second
        // hold returns here and a swipe off the controls cannot resume the
        // timer or GPS while the workout is being saved.
        guard phase == .running || phase == .paused else { return }
        phase = .finishing
        lastRunQueued = false
        stopTicker()
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        bannerKm = nil
        bannerUntil = nil
        Self.buzz(.stop)
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
                totalSteps: totalSteps,
                gpsRoute: routePoints,
                paceSamples: paceSamples
            )
            queue.enqueueRun(pending)
            lastRunQueued = true
            if totalSteps > 0 {
                let dayKey = Self.kstDayKey(for: end)
                queue.enqueueSteps(dayKey: dayKey, steps: totalSteps)
            }
            // Show the summary first; its reward line fills in when the server answers
            // (and stays "confirmed after upload" while offline).
            phase = .summary
            await queue.flush(using: account)
        } else {
            phase = .summary
        }
    }

    func resetToStart() {
        phase = .start
        lastActivityId = nil
        lastRunQueued = false
        routePoints.removeAll()
    }

    private func startTicker() {
        stopTicker()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.phase == .running else { return }
                self.movingSeconds += 1
                if let until = self.bannerUntil, Date() >= until {
                    self.bannerKm = nil
                    self.bannerUntil = nil
                }
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

    /// Each whole km: one strong tap and a short "{n} km passed" line (Wear OS `kmPassed`).
    private func noteDistance() {
        let whole = Int(distanceKm.rounded(.down))
        guard whole > wholeKm else { return }
        wholeKm = whole
        bannerKm = whole
        bannerUntil = Date().addingTimeInterval(5)
        Self.buzz(.notification)
    }

    private func notePace() {
        guard distanceKm + 0.000_001 >= lastPaceKm + 0.05 else { return }
        let pace = paceSecondsPerKm
        guard pace > 0 else { return }
        lastPaceKm = distanceKm
        paceSamples.append(
            WatchPaceSample(
                secondsPerKm: pace,
                recordedAt: ISO8601DateFormatter().string(from: Date())
            )
        )
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
                        if hkKm > self.distanceKm, self.phase == .running {
                            self.distanceKm = hkKm
                            self.noteDistance()
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
                        self.notePace()
                        self.noteDistance()
                    }
                }
                self.routePoints.append(
                    WatchRoutePoint(
                        latitude: loc.coordinate.latitude,
                        longitude: loc.coordinate.longitude,
                        recordedAt: ISO8601DateFormatter().string(from: loc.timestamp)
                    )
                )
                if self.routePoints.count > 400 {
                    self.routePoints.removeFirst(self.routePoints.count - 400)
                }
                self.lastLocation = loc
            }
        }
    }
}
