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
                WatchGlanceTabs {
                    WatchStartView(
                        targetKm: workout.targetKm,
                        linkedName: account.isPaired ? (account.nickname.isEmpty ? WatchCopy.current.linked : account.nickname) : nil,
                        onStart: {
                            Task { await workout.startRun() }
                        },
                        onLongPress: {
                            workout.phase = .pairing
                        }
                    )
                }
            case .running:
                WatchGlanceTabs {
                    WatchRunningView(
                        paceText: Self.formatPace(workout.paceSecondsPerKm),
                        heartRate: workout.lastHeartRate,
                        distanceText: Self.formatKm(workout.distanceKm),
                        cadenceSpm: workout.cadenceSpm,
                        onTap: { workout.pauseRun() }
                    )
                }
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
        .task {
            await account.refreshGlance()
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
        WatchCopy.minutes(max(0, seconds) / 60)
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
            Text(linkedName ?? WatchCopy.current.start)
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "play.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text(String(format: "%.0fkm", targetKm))
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(watchInk)
            Text(linkedName == nil ? "\(WatchCopy.current.tapToStart) · \(WatchCopy.current.pairingHint)" : WatchCopy.current.tapToStart)
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
            Text(message.map(WatchCopy.displayMessage) ?? (busy ? WatchCopy.current.checking : WatchCopy.current.pairingHint))
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
                keypadButton(WatchCopy.current.later, action: busy ? nil : onSkip)
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
            Text(WatchCopy.current.running)
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
            Text(WatchCopy.current.paused)
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "pause.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text(WatchCopy.current.paused)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(watchInk)
            Text(WatchCopy.current.pauseHint)
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
            Text(WatchCopy.current.rankAlert)
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "trophy.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text(WatchCopy.rankPlace(rank))
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(watchInk)
            Text(gapPeople > 0 ? WatchCopy.current.ahead(of: gapPeople) : WatchCopy.current.leading)
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
            Text(WatchCopy.current.done)
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(watchLime)
            Text("\(distanceText)km")
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(watchInk)
            Text("\(paceText)/km · \(minutesText)\n\(pendingCount > 0 ? WatchCopy.current.uploadPending(pendingCount) : WatchCopy.current.nothingToUpload)")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(watchMuted)
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onDone)
    }
}

/// First page is the existing start or run screen. The next four are read-only.
struct WatchGlanceTabs<First: View>: View {
    @ViewBuilder var first: () -> First

    var body: some View {
        TabView {
            first()
            WatchGlancePage(kind: .world)
            WatchGlancePage(kind: .challenge)
            WatchGlancePage(kind: .crew)
            WatchGlancePage(kind: .diamond)
        }
        .tabViewStyle(.page)
    }
}

enum WatchGlanceKind { case world, challenge, crew, diamond }

/// One fact, large type. Diamond does not buy anything; it tells you to open the phone shop.
struct WatchGlancePage: View {
    @EnvironmentObject var account: WatchAccountManager
    let kind: WatchGlanceKind

    var body: some View {
        let lines = WatchGlanceLines.make(kind: kind, account: account)
        VStack(spacing: 4) {
            Text(lines.title)
                .font(.system(size: 12))
                .foregroundColor(watchMuted)
            Text(lines.headline)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(watchInk)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            if !lines.detail.isEmpty {
                Text(lines.detail)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(watchInk)
                    .multilineTextAlignment(.center)
            }
            if !lines.foot.isEmpty {
                Text(lines.foot)
                    .font(.system(size: 11))
                    .foregroundColor(watchMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(8)
    }
}

struct WatchGlanceLines {
    var title: String
    var headline: String
    var detail: String = ""
    var foot: String = ""

    static func make(kind: WatchGlanceKind, account: WatchAccountManager) -> WatchGlanceLines {
        let title: String
        switch kind {
        case .world: title = WatchCopy.glance("glanceWorld")
        case .challenge: title = WatchCopy.glance("glanceChallenge")
        case .crew: title = WatchCopy.glance("glanceCrew")
        case .diamond: title = "DIA"
        }
        if !account.isPaired {
            return WatchGlanceLines(title: title, headline: WatchCopy.glance("glanceUnpaired"))
        }
        guard let glance = account.glance else {
            let headline = account.glanceFailed
                ? WatchCopy.glance("glanceOffline")
                : WatchCopy.current.checking
            return WatchGlanceLines(title: title, headline: headline)
        }
        switch kind {
        case .world:
            guard glance.hasWorld else {
                return WatchGlanceLines(title: title, headline: WatchCopy.glance("glanceOffline"))
            }
            let progress = WatchCopy.glance("glanceOverall", n: "\(glance.completed)/\(glance.total)")
            if glance.allDone {
                return WatchGlanceLines(title: title, headline: WatchCopy.glance("glanceAllDone"), detail: progress)
            }
            let city = WatchPlaces.name(glance.landmarkId, city: true) ?? glance.title
            let country = WatchPlaces.name(glance.landmarkId, city: false) ?? ""
            return WatchGlanceLines(
                title: title,
                headline: city,
                detail: country,
                foot: WatchCopy.glance("glanceRemain", n: formatGlanceKm(glance.remainingKm)) + "\n" + progress
            )
        case .challenge:
            let today = "\(formatGlanceKm(glance.todayKm))/\(formatGlanceKm(glance.todayTarget)) km"
            let week = "\(formatGlanceKm(glance.weekKm))/\(formatGlanceKm(glance.weekTarget)) km"
            let foot: String
            if !glance.hasRace {
                foot = WatchCopy.glance("glanceNoRace")
            } else if let rank = glance.raceRank {
                foot = WatchCopy.rankPlace(rank)
            } else {
                foot = WatchCopy.glance("glanceInRace")
            }
            return WatchGlanceLines(
                title: title,
                headline: today,
                detail: WatchCopy.glance("glanceWeekLine", n: week),
                foot: foot
            )
        case .crew:
            guard glance.hasCrew else {
                return WatchGlanceLines(title: title, headline: WatchCopy.glance("glanceNoCrew"))
            }
            let foot = glance.crewRank.map { WatchCopy.glance("glanceMonthRank", n: "\($0)") }
                ?? WatchCopy.glance("glanceUnranked")
            return WatchGlanceLines(
                title: glance.crewName.isEmpty ? title : glance.crewName,
                headline: "\(formatGlanceKm(glance.crewWeekKm)) km",
                detail: WatchCopy.glance("glanceWeekLine", n: "\(formatGlanceKm(glance.crewWeekKm)) km"),
                foot: foot
            )
        case .diamond:
            return WatchGlanceLines(
                title: "",
                headline: WatchCopy.glance("glanceDia", n: "\(glance.diamond)"),
                detail: WatchCopy.glance("glanceShopHint")
            )
        }
    }
}

func formatGlanceKm(_ km: Double) -> String {
    guard km.isFinite, km >= 0 else { return "0" }
    let rounded = (km * 10).rounded() / 10
    if abs(rounded - rounded.rounded()) < 0.001 {
        return String(Int(rounded.rounded()))
    }
    return String(format: "%.1f", rounded)
}

enum WatchPlaces {
    private static let order = ["ko", "en", "ja", "zh", "es", "pt", "de", "fr", "vi", "th", "id"]
    private static let country: [String: [String]] = [
        "eiffel_tower": ["프랑스", "France", "フランス", "法國", "Francia", "França", "Frankreich", "France", "Pháp", "ฝรั่งเศส", "Prancis"],
        "taj_mahal": ["인도", "India", "インド", "印度", "India", "Índia", "Indien", "Inde", "Ấn Độ", "อินเดีย", "India"],
        "mount_fuji": ["일본", "Japan", "日本", "日本", "Japón", "Japão", "Japan", "Japon", "Nhật Bản", "ญี่ปุ่น", "Jepang"],
        "big_ben": ["영국", "United Kingdom", "イギリス", "英國", "Reino Unido", "Reino Unido", "Vereinigtes Königreich", "Royaume-Uni", "Anh", "สหราชอาณาจักร", "Britania Raya"],
        "statue_of_liberty": ["미국", "United States", "アメリカ", "美國", "Estados Unidos", "Estados Unidos", "Vereinigte Staaten", "États-Unis", "Mỹ", "สหรัฐ", "Amerika Serikat"],
        "gwanghwamun": ["한국", "Korea", "韓国", "韓國", "Corea", "Coreia", "Korea", "Corée", "Hàn Quốc", "เกาหลี", "Korea"],
        "taroko_gorge": ["대만", "Taiwan", "台湾", "台灣", "Taiwán", "Taiwan", "Taiwan", "Taïwan", "Đài Loan", "ไต้หวัน", "Taiwan"],
        "alhambra": ["스페인", "Spain", "スペイン", "西班牙", "España", "Espanha", "Spanien", "Espagne", "Tây Ban Nha", "สเปน", "Spanyol"],
        "iguazu_falls": ["브라질", "Brazil", "ブラジル", "巴西", "Brasil", "Brasil", "Brasilien", "Brésil", "Brazil", "บราซิล", "Brasil"],
        "neuschwanstein": ["독일", "Germany", "ドイツ", "德國", "Alemania", "Alemanha", "Deutschland", "Allemagne", "Đức", "เยอรมนี", "Jerman"],
        "ha_long_bay": ["베트남", "Vietnam", "ベトナム", "越南", "Vietnam", "Vietnã", "Vietnam", "Viêt Nam", "Việt Nam", "เวียดนาม", "Vietnam"],
        "ayutthaya": ["태국", "Thailand", "タイ", "泰國", "Tailandia", "Tailândia", "Thailand", "Thaïlande", "Thái Lan", "ไทย", "Thailand"],
        "bali_rice_terraces": ["인도네시아", "Indonesia", "インドネシア", "印尼", "Indonesia", "Indonésia", "Indonesien", "Indonésie", "Indonesia", "อินโดนีเซีย", "Indonesia"],
    ]
    private static let city: [String: [String]] = [
        "eiffel_tower": ["파리", "Paris", "パリ", "巴黎", "París", "Paris", "Paris", "Paris", "Paris", "ปารีส", "Paris"],
        "taj_mahal": ["아그라", "Agra", "アグラ", "阿格拉", "Agra", "Agra", "Agra", "Agra", "Agra", "อักรา", "Agra"],
        "mount_fuji": ["후지", "Fuji", "富士", "富士", "Fuji", "Fuji", "Fuji", "Fuji", "Phú Sĩ", "ฟูจิ", "Fuji"],
        "big_ben": ["런던", "London", "ロンドン", "倫敦", "Londres", "Londres", "London", "Londres", "Luân Đôn", "ลอนดอน", "London"],
        "statue_of_liberty": ["뉴욕", "New York", "ニューヨーク", "紐約", "Nueva York", "Nova York", "New York", "New York", "New York", "นิวยอร์ก", "New York"],
        "gwanghwamun": ["서울", "Seoul", "ソウル", "首爾", "Seúl", "Seul", "Seoul", "Séoul", "Seoul", "โซล", "Seoul"],
        "taroko_gorge": ["화롄", "Hualien", "花蓮", "花蓮", "Hualien", "Hualien", "Hualien", "Hualien", "Hoa Liên", "ฮวาเหลียน", "Hualien"],
        "alhambra": ["그라나다", "Granada", "グラナダ", "格拉納達", "Granada", "Granada", "Granada", "Grenade", "Granada", "กรานาดา", "Granada"],
        "iguazu_falls": ["이구아수", "Iguazu", "イグアス", "伊瓜蘇", "Iguazú", "Iguaçu", "Iguaçu", "Iguaçu", "Iguazu", "อีกวาซู", "Iguazu"],
        "neuschwanstein": ["슈방가우", "Schwangau", "シュヴァンガウ", "施旺高", "Schwangau", "Schwangau", "Schwangau", "Schwangau", "Schwangau", "ชวานเกา", "Schwangau"],
        "ha_long_bay": ["하롱", "Ha Long", "ハロン", "下龍", "Ha Long", "Ha Long", "Ha Long", "Ha Long", "Hạ Long", "ฮาลอง", "Ha Long"],
        "ayutthaya": ["아유타야", "Ayutthaya", "アユタヤ", "大城", "Ayutthaya", "Ayutthaya", "Ayutthaya", "Ayutthaya", "Ayutthaya", "อยุธยา", "Ayutthaya"],
        "bali_rice_terraces": ["발리", "Bali", "バリ", "峇里", "Bali", "Bali", "Bali", "Bali", "Bali", "บาหลี", "Bali"],
    ]

    static func name(_ landmark: String, city wantCity: Bool) -> String? {
        let table = wantCity ? city : country
        guard let row = table[landmark], !row.isEmpty else { return nil }
        let code = Locale.current.languageCode ?? "en"
        let index = order.firstIndex(of: code) ?? 1
        return row.indices.contains(index) ? row[index] : row[min(1, row.count - 1)]
    }
}
