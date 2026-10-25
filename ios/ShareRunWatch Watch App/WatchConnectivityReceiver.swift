import Foundation
import WatchConnectivity

/// Bridges companion iPhone app (`WatchBridgePlugin.swift`) with Apple Watch for:
/// 1) Instant token/account handoff without typing 6 digits when phone is nearby
/// 2) Live tournament rank alert push (`rank`, `gapPeople`)
/// 3) Relaying offline runs when Watch has no direct Wi-Fi/LTE
@MainActor
final class WatchConnectivityReceiver: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var latestRankAlert: (rank: Int, gapPeople: Int)?

    private weak var account: WatchAccountManager?
    private weak var queue: WatchSyncQueue?

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func bind(account: WatchAccountManager, queue: WatchSyncQueue) {
        self.account = account
        self.queue = queue
    }

    func sendCompletedRunToPhone(_ run: WatchPendingRun) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo([
            "type": "watch_run_completed",
            "payload": run.toValidateRunBody()
        ])
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handleIncoming(message)
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        handleIncoming(userInfo)
    }

    nonisolated private func handleIncoming(_ data: [String: Any]) {
        let type = data["type"] as? String
        Task { @MainActor in
            switch type {
            case "companion_auth":
                if let refresh = data["refreshToken"] as? String, !refresh.isEmpty {
                    let nick = (data["nickname"] as? String) ?? ""
                    self.account?.applyCompanionCredentials(refreshToken: refresh, nickname: nick)
                    if let acc = self.account {
                        await self.queue?.flush(using: acc)
                    }
                }
            case "rank_alert":
                if let rank = data["rank"] as? Int {
                    let gap = (data["gapPeople"] as? Int) ?? 0
                    self.latestRankAlert = (rank: rank, gapPeople: gap)
                }
            default:
                break
            }
        }
    }
}
