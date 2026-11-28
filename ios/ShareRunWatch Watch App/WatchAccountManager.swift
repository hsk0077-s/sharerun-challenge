import Foundation
import Security

/// Handles 6-digit pairing (`POST /auth/watch-pair` -> Firebase Custom Token -> ID/Refresh Token)
/// and signed requests to ShareRun backend (`/actions/runs/validate`, `/actions/daily-steps`).
@MainActor
final class WatchAccountManager: ObservableObject {
    @Published private(set) var isPaired: Bool = false
    @Published private(set) var nickname: String = ""
    @Published private(set) var isBusy: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var glance: WatchGlanceData?
    @Published private(set) var glanceFailed: Bool = false
    /// Tier animal code from the server (`turtle`, `cheetah_gold` …). Nil before grading.
    @Published private(set) var tierCode: String?

    private let defaults = UserDefaults.standard
    private let refreshKey = "sharerun.watch.refresh_token"
    private let nicknameKey = "sharerun.watch.nickname"
    private let deviceKey = "sharerun.watch.device_id"
    private let tierKey = "sharerun.watch.tier_code"

    private var refreshToken: String?
    private var idToken: String?
    private var idTokenExpiresAt: Date = .distantPast

    var jenaBaseUrl: String {
        Bundle.main.object(forInfoDictionaryKey: "JENA_BASE_URL") as? String ?? ""
    }

    var firebaseApiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "FIREBASE_API_KEY") as? String ?? ""
    }

    var isConfigured: Bool {
        !jenaBaseUrl.isEmpty && !firebaseApiKey.isEmpty
    }

    init() {
        self.refreshToken = defaults.string(forKey: refreshKey)
        self.nickname = defaults.string(forKey: nicknameKey) ?? ""
        self.isPaired = !(self.refreshToken ?? "").isEmpty
        self.tierCode = defaults.string(forKey: tierKey)
    }

    /// Keeps the `tier_code` from a pair, upload or tier reply. An empty or
    /// missing value keeps the one we already have (same as Wear OS `rememberTier`).
    func rememberTier(_ raw: Any?) {
        guard let code = raw as? String, !code.isEmpty, code != tierCode else { return }
        tierCode = code
        defaults.set(code, forKey: tierKey)
    }

    /// `POST /actions/watch/tier` when the app opens. Failure keeps the last value.
    func refreshTier() async {
        guard isPaired else { return }
        guard let (status, body) = await postSigned(path: "/actions/watch/tier", payload: [:]),
              (200..<300).contains(status) else { return }
        rememberTier(body["tier_code"])
    }

    /// Stable id for `POST /auth/watch-pair` and `ValidateRunRequest.device_id`.
    /// Unpair keeps it so the same watch does not look like a new handset.
    func deviceId() -> String {
        if let saved = defaults.string(forKey: deviceKey),
           saved.range(of: #"^[A-Za-z0-9_-]{8,64}$"#, options: .regularExpression) != nil {
            return saved
        }
        let fresh = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        defaults.set(fresh, forKey: deviceKey)
        return fresh
    }

    func applyCompanionCredentials(refreshToken: String, nickname: String) {
        self.refreshToken = refreshToken
        self.nickname = nickname
        self.isPaired = !refreshToken.isEmpty
        defaults.set(refreshToken, forKey: refreshKey)
        defaults.set(nickname, forKey: nicknameKey)
    }

    func unpair() {
        refreshToken = nil
        idToken = nil
        idTokenExpiresAt = .distantPast
        nickname = ""
        isPaired = false
        tierCode = nil
        defaults.removeObject(forKey: refreshKey)
        defaults.removeObject(forKey: nicknameKey)
        defaults.removeObject(forKey: tierKey)
    }

    /// Exchanges 6-digit code from phone (`POST /actions/watch-pairing/code`) via `POST /auth/watch-pair`.
    func pair(withCode code: String) async -> String? {
        guard isConfigured else {
            let msg = "no_server"
            errorMessage = msg
            return msg
        }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(of: #"^\d{6}$"#, options: .regularExpression) != nil else {
            let msg = "need_six_digits"
            errorMessage = msg
            return msg
        }

        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        guard let pairUrl = URL(string: "\(jenaBaseUrl)/auth/watch-pair") else {
            return "bad_url"
        }

        do {
            let (status, body) = try await postJson(
                url: pairUrl,
                payload: [
                    "code": trimmed,
                    "device_id": deviceId(),
                    "device_label": "Apple Watch",
                ]
            )
            if status == 429 {
                let msg = "rate_limited"
                errorMessage = msg
                return msg
            }
            guard (200..<300).contains(status),
                  let customToken = body["custom_token"] as? String,
                  !customToken.isEmpty else {
                let msg = "bad_code"
                errorMessage = msg
                return msg
            }

            guard let authUrl = URL(
                string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=\(firebaseApiKey)"
            ) else {
                return "auth_url"
            }

            let (authStatus, authBody) = try await postJson(
                url: authUrl,
                payload: ["token": customToken, "returnSecureToken": true]
            )
            guard (200..<300).contains(authStatus),
                  let refresh = authBody["refreshToken"] as? String,
                  let token = authBody["idToken"] as? String else {
                let msg = "sign_in_failed"
                errorMessage = msg
                return msg
            }

            let expiresIn = Int("\(authBody["expiresIn"] ?? "3600")") ?? 3600
            self.idToken = token
            self.idTokenExpiresAt = Date().addingTimeInterval(TimeInterval(max(60, expiresIn - 60)))
            self.refreshToken = refresh
            self.nickname = (body["nickname"] as? String) ?? ""
            self.isPaired = true

            defaults.set(refresh, forKey: refreshKey)
            defaults.set(self.nickname, forKey: nicknameKey)
            rememberTier(body["tier_code"])
            return nil
        } catch {
            let msg = "offline"
            errorMessage = msg
            return msg
        }
    }

    func validIdToken(forceRefresh: Bool = false) async -> String? {
        guard isPaired, isConfigured, let refresh = refreshToken else { return nil }
        if !forceRefresh, let token = idToken, Date() < idTokenExpiresAt {
            return token
        }
        guard let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=\(firebaseApiKey)") else {
            return nil
        }
        do {
            let (status, body) = try await postJson(
                url: url,
                payload: ["grant_type": "refresh_token", "refresh_token": refresh]
            )
            guard (200..<300).contains(status),
                  let fresh = body["id_token"] as? String else {
                if status == 400 || status == 401 {
                    unpair()
                }
                return nil
            }
            if let rotated = body["refresh_token"] as? String, !rotated.isEmpty, rotated != refresh {
                self.refreshToken = rotated
                defaults.set(rotated, forKey: refreshKey)
            }
            let expiresIn = Int("\(body["expires_in"] ?? "3600")") ?? 3600
            self.idToken = fresh
            self.idTokenExpiresAt = Date().addingTimeInterval(TimeInterval(max(60, expiresIn - 60)))
            return fresh
        } catch {
            return nil
        }
    }

    /// Read-only board. `device_id` matches a run upload; the token picks the account.
    func refreshGlance() async {
        guard isPaired else { return }
        guard let (status, body) = await postSigned(
            path: "/actions/watch/glance",
            payload: ["device_id": deviceId()]
        ), (200..<300).contains(status),
              let parsed = WatchGlanceData.parse(body) else {
            if glance == nil { glanceFailed = true }
            return
        }
        glance = parsed
        glanceFailed = false
    }

    func postSigned(path: String, payload: [String: Any]) async -> (Int, [String: Any])? {
        for attempt in 0..<2 {
            guard let token = await validIdToken(forceRefresh: attempt > 0),
                  let url = URL(string: "\(jenaBaseUrl)\(path)") else {
                return nil
            }
            do {
                let (status, body) = try await postJson(
                    url: url,
                    payload: payload,
                    headers: ["Authorization": "Bearer \(token)"]
                )
                if status != 401 {
                    return (status, body)
                }
            } catch {
                return nil
            }
        }
        return nil
    }

    private func postJson(
        url: URL,
        payload: [String: Any],
        headers: [String: String] = [:]
    ) async throws -> (Int, [String: Any]) {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (k, v) in headers {
            req.setValue(v, forHTTPHeaderField: k)
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return (status, json)
    }
}

/// One `POST /actions/watch/glance` body. Empty pieces stay nil.
struct WatchGlanceData {
    var diamond: Int = 0
    var landmarkId: String = ""
    var title: String = ""
    var remainingKm: Double = 0
    var completed: Int = 0
    var total: Int = 0
    var allDone: Bool = false
    var hasWorld: Bool = false
    var todayKm: Double = 0
    var todayTarget: Double = 0
    var weekKm: Double = 0
    var weekTarget: Double = 0
    var raceRank: Int?
    var hasRace: Bool = false
    var crewName: String = ""
    var crewWeekKm: Double = 0
    var crewRank: Int?
    var hasCrew: Bool = false

    static func parse(_ json: [String: Any]) -> WatchGlanceData? {
        guard let goals = json["goals"] as? [String: Any], goals["today_target_km"] != nil else {
            return nil
        }
        var data = WatchGlanceData()
        data.diamond = max(0, intValue(json["diamond_balance"]))
        data.todayKm = kmValue(goals["today_km"])
        data.todayTarget = kmValue(goals["today_target_km"])
        data.weekKm = kmValue(goals["week_km"])
        data.weekTarget = kmValue(goals["week_target_km"])
        if let world = json["world_tour"] as? [String: Any],
           let landmark = world["landmark_id"] as? String, !landmark.isEmpty {
            data.hasWorld = true
            data.landmarkId = landmark
            data.title = world["title"] as? String ?? ""
            data.remainingKm = kmValue(world["remaining_km"])
            data.completed = intValue(world["completed_count"])
            data.total = intValue(world["total_count"])
            data.allDone = world["all_done"] as? Bool ?? false
        }
        if let race = json["race"] as? [String: Any],
           let id = race["tournament_id"] as? String, !id.isEmpty {
            data.hasRace = true
            let rank = intValue(race["rank"])
            data.raceRank = rank >= 1 ? rank : nil
        }
        if let crew = json["crew"] as? [String: Any] {
            data.hasCrew = true
            data.crewName = crew["name"] as? String ?? ""
            data.crewWeekKm = kmValue(crew["week_km"])
            let rank = intValue(crew["rank"])
            data.crewRank = rank >= 1 ? rank : nil
        }
        return data
    }

    private static func kmValue(_ raw: Any?) -> Double {
        let value = (raw as? NSNumber)?.doubleValue ?? 0
        return value.isFinite && value >= 0 ? value : 0
    }

    private static func intValue(_ raw: Any?) -> Int {
        let value = (raw as? NSNumber)?.intValue ?? 0
        return value >= 0 ? value : 0
    }
}
