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

    private let defaults = UserDefaults.standard
    private let refreshKey = "sharerun.watch.refresh_token"
    private let nicknameKey = "sharerun.watch.nickname"

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
        defaults.removeObject(forKey: refreshKey)
        defaults.removeObject(forKey: nicknameKey)
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
            let (status, body) = try await postJson(url: pairUrl, payload: ["code": trimmed])
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
