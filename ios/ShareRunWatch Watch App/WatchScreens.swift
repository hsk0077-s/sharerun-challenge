import SwiftUI

private let watchBg = Color(red: 0.043, green: 0.059, blue: 0.047)
private let watchLime = Color(red: 0.831, green: 1.0, blue: 0.290)
private let watchInk = Color(red: 0.957, green: 0.969, blue: 0.941)
private let watchMuted = Color(red: 0.663, green: 0.698, blue: 0.651)

/// Root router mirroring all 5+1 screens of `wear_app/lib/screens/watch_screens.dart`:
/// ⓪ PairingFace (6-digit keypad `/auth/watch-pair`)
/// ① StartFace (target km, tap to start, long-press to pair)
/// ② RunningFace (live pace, heart rate BPM, distance km, cadence)
/// ③ PausedFace (tap to resume, long-press to finish)
/// ④ RankAlertFace (live tournament rank banner)
/// ⑤ SummaryFace (finish summary + offline sync queue count)
struct WatchRootView: View {
    @EnvironmentObject var workout: WorkoutManager
    @EnvironmentObject var account: WatchAccountManager
    @EnvironmentObject var queue: WatchSyncQueue
    @EnvironmentObject var connectivity: WatchConnectivityReceiver

    var body: some View {
        ZStack {
            watchBg.ignoresSafeArea()
            switch workout.phase {
            case .pairing:
                WatchPairingView(
                    onSubmit: { code in
                        let err = await account.pair(withCode: code)
                        if err == nil {
                            await queue.flush(using: account)
                            workout.phase = .start
                        }
                        return err
                    },
                    onSkip: { workout.phase = .start }
                )
            case .start:
                WatchStartView(
                    targetKm: workout.targetKm,
                    linkedName: account.isPaired ? (account.nickname.isEmpty ? "연결됨" : account.nickname) : nil,
                    onStart: {
                        Task { await workout.startRun() }
                    },
                    onLongPress: {
                        workout.phase = .pairing
                    }
                )
            case .running:
                WatchRunningView(
                    paceText: Self.formatPace(workout.paceSecondsPerKm),
                    heartRate: workout.lastHeartRate,
                    distanceText: Self.formatKm(workout.distanceKm),
                    cadenceSpm: workout.cadenceSpm,
                    onTap: { workout.pauseRun() }
                )
            case .paused:
                WatchPausedView(
                    onResume: { workout.resumeRun() },
                    onFinish: {
                        Task { await workout.finishRun(into: queue, account: account) }
                    }
                )
            case let .rankAlert(rank, gapPeople):
                WatchRankAlertView(
                    rank: rank,
                    gapPeople: gapPeople,
                    onDismiss: { workout.dismissRankAlert() }
                )
            case .summary:
                WatchSummaryView(
                    distanceText: Self.formatKm(workout.distanceKm),
                    paceText: Self.formatPace(workout.paceSecondsPerKm),
                    minutesText: Self.formatMinutes(workout.movingSeconds),
                    pendingCount: queue.pendingCount,
                    onDone: { workout.resetToStart() }
                )
            }
        }
        .onChange(of: connectivity.latestRankAlert?.rank) { _ in
            if let alert = connectivity.latestRankAlert {
                workout.showRankAlert(rank: alert.rank, gapPeople: alert.gapPeople)
            }
        }
    }

    static func formatPace(_ secPerKm: Int) -> String {
        guard secPerKm > 0 && secPerKm < 3600 else { return "-'--\"" }
        let m = secPerKm / 60
        let s = secPerKm % 60
        return String(format: "%d'%02d\"", m, s)
    }

    static func formatKm(_ km: Double) -> String {
        String(format: "%.2f", max(0, km))
    }

    static func formatMinutes(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        return "\(m)분"
    }
}

/// ① 시작 화면
struct WatchStartView: View {
    let targetKm: Double
    let linkedName: String?
    let onStart: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(linkedName ?? "시작")
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "play.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text(String(format: "%.0fkm", targetKm))
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(watchInk)
            Text(linkedName == nil ? "탭해서 시작 · 길게 눌러 6자리 연결" : "탭해서 시작")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(watchMuted)
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onStart)
        .onLongPressGesture(perform: onLongPress)
    }
}

/// ⓪ 6자리 페어링 화면 (`/auth/watch-pair`)
struct WatchPairingView: View {
    let onSubmit: (String) async -> String?
    let onSkip: () -> Void

    @State private var code: String = ""
    @State private var busy: Bool = false
    @State private var message: String?

    private var displayCode: String {
        let padded = code.padding(toLength: 6, withPad: "•", startingAt: 0)
        let prefix = padded.prefix(3)
        let suffix = padded.suffix(3)
        return "\(prefix) \(suffix)"
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(message ?? (busy ? "확인하는 중" : "휴대폰 앱의 6자리"))
                .font(.system(size: 10))
                .foregroundColor(message == nil ? watchMuted : Color.red.opacity(0.85))
                .lineLimit(1)
            Text(displayCode)
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .foregroundColor(watchLime)

            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(row, id: \.self) { digit in
                        keypadButton("\(digit)") {
                            pressDigit("\(digit)")
                        }
                    }
                }
            }
            HStack(spacing: 3) {
                keypadButton("나중에", action: busy ? nil : onSkip)
                keypadButton("0") { pressDigit("0") }
                keypadButton("←", action: backspace)
            }
        }
        .padding(6)
    }

    private func keypadButton(_ title: String, action: (() -> Void)?) -> some View {
        Button(action: { action?() }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(watchInk)
                .frame(maxWidth: .infinity, minHeight: 24)
                .background(Color(red: 0.106, green: 0.137, blue: 0.114))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func pressDigit(_ d: String) {
        guard !busy, code.count < 6 else { return }
        code.append(d)
        message = nil
        if code.count == 6 {
            let submitted = code
            busy = true
            Task {
                let err = await onSubmit(submitted)
                busy = false
                if let err = err {
                    message = err
                    code = ""
                }
            }
        }
    }

    private func backspace() {
        guard !busy, !code.isEmpty else { return }
        code.removeLast()
        message = nil
    }
}

/// ② 달리는 중 HUD (페이스·심박·거리·케이던스)
struct WatchRunningView: View {
    let paceText: String
    let heartRate: Int
    let distanceText: String
    let cadenceSpm: Int
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("달리는 중")
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "figure.run")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text(paceText)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(watchInk)
            Text("\(heartRate > 0 ? "♥ \(heartRate)" : "♥ --") · \(distanceText)km")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(watchMuted)
            if cadenceSpm > 0 {
                Text("\(cadenceSpm) spm")
                    .font(.system(size: 10))
                    .foregroundColor(watchMuted.opacity(0.8))
            }
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

/// ③ 일시정지/재개/종료 화면
struct WatchPausedView: View {
    let onResume: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("일시정지")
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "pause.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text("일시정지")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(watchInk)
            Text("탭해서 다시 시작\n길게 눌러 끝내기")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(watchMuted)
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onResume)
        .onLongPressGesture(perform: onFinish)
    }
}

/// ④ 실시간 대회 순위 알림 배너
struct WatchRankAlertView: View {
    let rank: Int
    let gapPeople: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("대회 알림")
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "trophy.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text("\(rank)위!")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(watchInk)
            Text(gapPeople > 0 ? "대회 \(gapPeople)명 앞서요" : "선두예요")
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss)
    }
}

/// ⑤ 완주 요약 + 오프라인 동기화 대기열 상태
struct WatchSummaryView: View {
    let distanceText: String
    let paceText: String
    let minutesText: String
    let pendingCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text("끝")
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text("\(distanceText)km")
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(watchInk)
            Text("\(paceText)/km · \(minutesText)\n\(pendingCount > 0 ? "휴대폰 연결 시 올려요 (\(pendingCount))" : "올릴 기록 없음")")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(watchMuted)
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
    }
}
