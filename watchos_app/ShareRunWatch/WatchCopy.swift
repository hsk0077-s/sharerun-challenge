import Foundation

/// Same 11 language codes as the phone dictionary. Watch faces only.
enum WatchCopy {
    static var current: Texts {
        let code = Locale.current.languageCode ?? "en"
        return all[code] ?? all["en"]!
    }

    struct Texts {
        let start: String
        let linked: String
        let tapToStart: String
        let pairingHint: String
        let checking: String
        let later: String
        let running: String
        let paused: String
        let pauseHint: String
        let rankAlert: String
        let leading: String
        let done: String
        let nothingToUpload: String

        func ahead(of people: Int) -> String {
            start == "시작" ? "대회 \(people)명 앞서요" : "\(rankAlert) +\(people)"
        }

        func uploadPending(_ count: Int) -> String {
            start == "시작" ? "휴대폰 연결 시 올려요 (\(count))" : "\(done) (\(count))"
        }
    }

    private static let all: [String: Texts] = [
        "ko": Texts(start: "시작", linked: "연결됨", tapToStart: "탭해서 시작", pairingHint: "휴대폰 앱의 6자리", checking: "확인하는 중", later: "나중에", running: "달리는 중", paused: "일시정지", pauseHint: "탭해서 다시 시작\n길게 눌러 끝내기", rankAlert: "대회 알림", leading: "선두예요", done: "끝", nothingToUpload: "올릴 기록 없음"),
        "en": Texts(start: "Start", linked: "Linked", tapToStart: "Tap to start", pairingHint: "6 digits from the phone", checking: "Checking", later: "Later", running: "Running", paused: "Paused", pauseHint: "Tap to resume\nHold to finish", rankAlert: "Race", leading: "In the lead", done: "Done", nothingToUpload: "Nothing to upload"),
        "ja": Texts(start: "開始", linked: "接続済み", tapToStart: "タップで開始", pairingHint: "スマホの6桁", checking: "確認中", later: "あとで", running: "走行中", paused: "一時停止", pauseHint: "タップで再開\n長押しで終了", rankAlert: "レース", leading: "先頭です", done: "終了", nothingToUpload: "送る記録なし"),
        "zh": Texts(start: "開始", linked: "已連結", tapToStart: "點一下開始", pairingHint: "手機上的 6 位數", checking: "確認中", later: "稍後", running: "跑步中", paused: "暫停", pauseHint: "點一下繼續\n長按結束", rankAlert: "比賽", leading: "目前領先", done: "結束", nothingToUpload: "沒有要上傳的紀錄"),
        "es": Texts(start: "Empezar", linked: "Vinculado", tapToStart: "Toca para empezar", pairingHint: "6 dígitos del teléfono", checking: "Comprobando", later: "Luego", running: "Corriendo", paused: "Pausa", pauseHint: "Toca para seguir\nMantén para terminar", rankAlert: "Carrera", leading: "Vas primero", done: "Fin", nothingToUpload: "Nada que subir"),
        "pt": Texts(start: "Começar", linked: "Ligado", tapToStart: "Toque para começar", pairingHint: "6 dígitos do telefone", checking: "Verificando", later: "Depois", running: "Correndo", paused: "Pausa", pauseHint: "Toque para continuar\nSegure para terminar", rankAlert: "Prova", leading: "Na frente", done: "Fim", nothingToUpload: "Nada para enviar"),
        "de": Texts(start: "Start", linked: "Verbunden", tapToStart: "Tippen zum Start", pairingHint: "6 Ziffern vom Telefon", checking: "Prüfen", later: "Später", running: "Läuft", paused: "Pause", pauseHint: "Tippen zum Weiter\nHalten zum Ende", rankAlert: "Rennen", leading: "In Führung", done: "Fertig", nothingToUpload: "Nichts zum Senden"),
        "fr": Texts(start: "Démarrer", linked: "Lié", tapToStart: "Touchez pour démarrer", pairingHint: "6 chiffres du téléphone", checking: "Vérification", later: "Plus tard", running: "Course", paused: "Pause", pauseHint: "Touchez pour reprendre\nMaintenez pour finir", rankAlert: "Course", leading: "En tête", done: "Fin", nothingToUpload: "Rien à envoyer"),
        "vi": Texts(start: "Bắt đầu", linked: "Đã nối", tapToStart: "Chạm để bắt đầu", pairingHint: "6 số trên điện thoại", checking: "Đang kiểm tra", later: "Để sau", running: "Đang chạy", paused: "Tạm dừng", pauseHint: "Chạm để chạy tiếp\nGiữ để kết thúc", rankAlert: "Giải", leading: "Đang dẫn đầu", done: "Xong", nothingToUpload: "Không có bản ghi để gửi"),
        "th": Texts(start: "เริ่ม", linked: "เชื่อมแล้ว", tapToStart: "แตะเพื่อเริ่ม", pairingHint: "รหัส 6 หลักจากโทรศัพท์", checking: "กำลังตรวจ", later: "ภายหลัง", running: "กำลังวิ่ง", paused: "พัก", pauseHint: "แตะเพื่อวิ่งต่อ\nกดค้างเพื่อจบ", rankAlert: "รายการ", leading: "นำอยู่", done: "จบ", nothingToUpload: "ไม่มีรายการจะส่ง"),
        "id": Texts(start: "Mulai", linked: "Terhubung", tapToStart: "Ketuk untuk mulai", pairingHint: "6 angka dari ponsel", checking: "Memeriksa", later: "Nanti", running: "Berlari", paused: "Jeda", pauseHint: "Ketuk untuk lanjut\nTahan untuk selesai", rankAlert: "Lomba", leading: "Di depan", done: "Selesai", nothingToUpload: "Tidak ada yang diunggah"),
    ]

    // 원어민 검수 전. 광고 랜딩에 쓰지 않는다.
    private static let languages = ["ko", "en", "ja", "zh", "es", "pt", "de", "fr", "vi", "th", "id"]

    private static let minutePatterns = [
        "ko": "{n}분", "en": "{n} min", "ja": "{n}分", "zh": "{n} 分",
        "es": "{n} min", "pt": "{n} min", "de": "{n} Min.", "fr": "{n} min",
        "vi": "{n} phút", "th": "{n} นาที", "id": "{n} mnt",
    ]

    private static let rankPatterns = [
        "ko": "{n}위", "en": "#{n}", "ja": "{n}位", "zh": "第{n}名",
        "es": "{n}.º", "pt": "{n}º", "de": "Platz {n}", "fr": "{n}e",
        "vi": "Hạng {n}", "th": "อันดับ {n}", "id": "Peringkat {n}",
    ]

    private static let pairing: [String: [String: String]] = [
        "no_server": [
            "ko": "서버 설정이 없는 빌드예요.",
            "en": "This build has no server settings.",
            "ja": "このビルドにはサーバー設定がありません。",
            "zh": "這個版本沒有伺服器設定。",
            "es": "Esta compilación no tiene servidor.",
            "pt": "Esta versão não tem servidor.",
            "de": "Dieser Build hat keine Serveradresse.",
            "fr": "Cette version n’a pas de serveur.",
            "vi": "Bản dựng này chưa có máy chủ.",
            "th": "รุ่นนี้ยังไม่มีการตั้งค่าเซิร์ฟเวอร์",
            "id": "Build ini belum punya server.",
        ],
        "need_six_digits": [
            "ko": "숫자 6자리를 입력해 주세요.",
            "en": "Enter 6 digits.",
            "ja": "6桁の数字を入力してください。",
            "zh": "請輸入 6 位數字。",
            "es": "Escribe 6 dígitos.",
            "pt": "Digite 6 números.",
            "de": "Bitte 6 Ziffern eingeben.",
            "fr": "Saisissez 6 chiffres.",
            "vi": "Nhập 6 chữ số.",
            "th": "กรอกตัวเลข 6 หลัก",
            "id": "Masukkan 6 angka.",
        ],
        "bad_url": [
            "ko": "잘못된 서버 주소예요.",
            "en": "The server address is invalid.",
            "ja": "サーバーアドレスが正しくありません。",
            "zh": "伺服器網址不正確。",
            "es": "La dirección del servidor no es válida.",
            "pt": "O endereço do servidor é inválido.",
            "de": "Die Serveradresse ist ungültig.",
            "fr": "L’adresse du serveur est invalide.",
            "vi": "Địa chỉ máy chủ không đúng.",
            "th": "ที่อยู่เซิร์ฟเวอร์ไม่ถูกต้อง",
            "id": "Alamat server tidak valid.",
        ],
        "rate_limited": [
            "ko": "잠시 뒤에 다시 해 주세요.",
            "en": "Try again in a moment.",
            "ja": "少し待ってからもう一度試してください。",
            "zh": "請稍後再試。",
            "es": "Inténtalo de nuevo en un momento.",
            "pt": "Tente de novo daqui a pouco.",
            "de": "Bitte kurz warten und erneut versuchen.",
            "fr": "Réessayez dans un instant.",
            "vi": "Hãy thử lại sau giây lát.",
            "th": "ลองอีกครั้งในอีกสักครู่",
            "id": "Coba lagi sebentar lagi.",
        ],
        "watch_limit": [
            "ko": "연결된 워치가 이미 3개예요. 휴대폰에서 하나를 해제해 주세요.",
            "en": "Three watches are already linked. Remove one on the phone.",
            "ja": "接続済みのウォッチがすでに3台です。スマホで1台解除してください。",
            "zh": "已連結 3 支手錶。請在手機上解除一支。",
            "es": "Ya hay 3 relojes vinculados. Quita uno en el teléfono.",
            "pt": "Já há 3 relógios ligados. Remova um no telefone.",
            "de": "Es sind schon 3 Uhren verbunden. Entferne eine am Telefon.",
            "fr": "3 montres sont déjà liées. Retirez-en une sur le téléphone.",
            "vi": "Đã nối 3 đồng hồ. Hãy gỡ một chiếc trên điện thoại.",
            "th": "เชื่อมนาฬิกาครบ 3 เรือนแล้ว โปรดยกเลิกหนึ่งเรือนบนโทรศัพท์",
            "id": "Sudah ada 3 jam terhubung. Lepas satu di ponsel.",
        ],
        "bad_code": [
            "ko": "코드가 맞지 않거나 만료됐어요.",
            "en": "The code is wrong or expired.",
            "ja": "コードが違うか、期限が切れています。",
            "zh": "代碼不對或已過期。",
            "es": "El código no es válido o caducó.",
            "pt": "O código está errado ou expirou.",
            "de": "Der Code stimmt nicht oder ist abgelaufen.",
            "fr": "Le code est faux ou expiré.",
            "vi": "Mã không đúng hoặc đã hết hạn.",
            "th": "รหัสไม่ถูกต้องหรือหมดอายุ",
            "id": "Kode salah atau kedaluwarsa.",
        ],
        "auth_url": [
            "ko": "Firebase 인증 주소 오류",
            "en": "Firebase sign-in address is invalid.",
            "ja": "Firebaseの認証アドレスが不正です。",
            "zh": "Firebase 驗證網址錯誤。",
            "es": "La dirección de acceso de Firebase no es válida.",
            "pt": "O endereço de login do Firebase é inválido.",
            "de": "Die Firebase-Anmeldeadresse ist ungültig.",
            "fr": "L’adresse de connexion Firebase est invalide.",
            "vi": "Địa chỉ đăng nhập Firebase không đúng.",
            "th": "ที่อยู่เข้าสู่ระบบ Firebase ไม่ถูกต้อง",
            "id": "Alamat masuk Firebase tidak valid.",
        ],
        "sign_in_failed": [
            "ko": "로그인을 마치지 못했어요. 다시 시도해 주세요.",
            "en": "Sign-in did not finish. Try again.",
            "ja": "ログインを完了できませんでした。もう一度試してください。",
            "zh": "登入沒有完成。請再試一次。",
            "es": "El acceso no terminó. Inténtalo otra vez.",
            "pt": "O login não terminou. Tente de novo.",
            "de": "Die Anmeldung wurde nicht fertig. Bitte erneut versuchen.",
            "fr": "La connexion ne s’est pas terminée. Réessayez.",
            "vi": "Đăng nhập chưa xong. Hãy thử lại.",
            "th": "การลงชื่อเข้าใช้ไม่สำเร็จ โปรดลองอีกครั้ง",
            "id": "Masuk belum selesai. Coba lagi.",
        ],
        "offline": [
            "ko": "연결할 수 없어요. 인터넷을 확인해 주세요.",
            "en": "Can’t connect. Check the internet.",
            "ja": "接続できません。インターネットを確認してください。",
            "zh": "連不上。請確認網路。",
            "es": "No hay conexión. Revisa internet.",
            "pt": "Não foi possível conectar. Verifique a internet.",
            "de": "Keine Verbindung. Bitte das Internet prüfen.",
            "fr": "Connexion impossible. Vérifiez internet.",
            "vi": "Không kết nối được. Hãy kiểm tra mạng.",
            "th": "เชื่อมต่อไม่ได้ โปรดตรวจอินเทอร์เน็ต",
            "id": "Tidak bisa terhubung. Periksa internet.",
        ],
    ]

    static func minutes(_ count: Int) -> String {
        fill(minutePatterns, count)
    }

    static func rankPlace(_ rank: Int) -> String {
        fill(rankPatterns, rank)
    }

    /// A pairing code becomes the locale sentence. Other text is left as written.
    static func displayMessage(_ raw: String) -> String {
        let code = Locale.current.languageCode ?? "en"
        guard let row = pairing[raw] else { return raw }
        return row[code] ?? row["en"] ?? raw
    }

    static func missingLocaleCodes() -> [String] {
        var missing: [String] = []
        for code in languages {
            if all[code] == nil { missing.append("face.\(code)") }
            if minutePatterns[code]?.isEmpty != false { missing.append("minutes.\(code)") }
            if rankPatterns[code]?.isEmpty != false { missing.append("rank.\(code)") }
        }
        for (key, row) in pairing {
            for code in languages where row[code]?.isEmpty != false {
                missing.append("pairing.\(key).\(code)")
            }
        }
        return missing
    }

    private static func fill(_ patterns: [String: String], _ count: Int) -> String {
        let code = Locale.current.languageCode ?? "en"
        let pattern = patterns[code] ?? patterns["en"] ?? "{n}"
        return pattern.replacingOccurrences(of: "{n}", with: "\(count)")
    }
}
