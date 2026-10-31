import 'package:flutter/widgets.dart';

import '../core/constants/legal_constants.dart';

/// Offline terms page. Korean matches the HTML the settings screen shipped.
/// Other locales are the same summary, not a substitute for the hosted policy.
String legalFallbackHtml(Locale locale) {
  final code = _pages.containsKey(locale.languageCode) ? locale.languageCode : 'en';
  final page = _pages[code]!;
  return '''
<!DOCTYPE html>
<html lang="${page.lang}">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, 'Pretendard', sans-serif;
         margin: 20px; color: #E8EFE6; background: #070B09; line-height: 1.55; }
  h1 { font-size: 20px; margin: 0 0 12px; }
  h2 { font-size: 16px; margin: 22px 0 8px; color: #D4FF4A; }
  p { font-size: 14px; margin: 0 0 10px; color: #93A299; }
  .note { background: #101813; padding: 12px 14px; border-radius: 12px;
          font-size: 13px; color: #D4FF4A; }
</style>
</head>
<body>
  <h1>${page.heading}</h1>
  <h2>${page.termsTitle}</h2>
  <p>${page.termsBody}</p>
  <h2>${page.privacyTitle}</h2>
  <p>${page.privacyBody}</p>
  <h2>${page.locationTitle}</h2>
  <p>${page.locationBody}</p>
  <h2>${page.healthTitle}</h2>
  <p>${page.healthBody}</p>
  <div class="note">${page.sensorNote}</div>
  <h2>${page.disclaimerTitle}</h2>
  <p>${page.disclaimerBody}</p>
</body>
</html>
''';
}

class _LegalPage {
  const _LegalPage({
    required this.lang,
    required this.heading,
    required this.termsTitle,
    required this.termsBody,
    required this.privacyTitle,
    required this.privacyBody,
    required this.locationTitle,
    required this.locationBody,
    required this.healthTitle,
    required this.healthBody,
    required this.sensorNote,
    required this.disclaimerTitle,
    required this.disclaimerBody,
  });

  final String lang;
  final String heading;
  final String termsTitle;
  final String termsBody;
  final String privacyTitle;
  final String privacyBody;
  final String locationTitle;
  final String locationBody;
  final String healthTitle;
  final String healthBody;
  final String sensorNote;
  final String disclaimerTitle;
  final String disclaimerBody;
}

final _pages = <String, _LegalPage>{
  'ko': _LegalPage(
    lang: 'ko',
    heading: '서비스 이용약관 및 개인정보 처리방침',
    termsTitle: LegalConstants.termsOfServiceTitle,
    termsBody: LegalConstants.termsOfServiceSummary,
    privacyTitle: LegalConstants.privacyPolicyTitle,
    privacyBody: LegalConstants.privacyPolicySummary,
    locationTitle: '위치기반서비스(LBS) 약관',
    locationBody:
        '러닝 검증·크루 맵·스탬프 투어를 위해 위치정보를 수집·이용합니다. 동의 철회 시 위치 기반 기능이 제한될 수 있습니다.',
    healthTitle: LegalConstants.healthDataConsentTitle,
    healthBody: LegalConstants.healthDataConsentSummary,
    sensorNote: LegalConstants.ephemeralSensorPolicy,
    disclaimerTitle: LegalConstants.healthDisclaimerTitle,
    disclaimerBody: LegalConstants.healthDisclaimer,
  ),
  'en': _LegalPage(
    lang: 'en',
    heading: 'Terms of service and privacy policy',
    termsTitle: 'Terms of service (required)',
    termsBody:
        'ShareRun offers verified running and race entry. Donations in the operator’s name follow the distance you run. Fake runs and payment abuse can limit the account.',
    privacyTitle: 'Privacy policy (required)',
    privacyBody:
        'Account identifiers, run-verification results, and payment-intent records are processed to run the service. Raw heart-rate and cadence samples are discarded as soon as Jena finishes checking the run. The full text is in the privacy policy.',
    locationTitle: 'Location service terms',
    locationBody:
        'Location is collected to verify runs, show the crew map, and run the stamp tour. If you withdraw consent, location features may stop.',
    healthTitle: 'Health data consent (optional, separate)',
    healthBody:
        'Heart rate and cadence from a watch, HealthKit, or Health Connect are used only to verify a run. You can use the app without consent. Watch linking and verified-run credit are limited without it. Raw heart-rate arrays are not stored in the server database and are dropped from memory right after verification.',
    sensorNote:
        'Raw heart-rate and cadence stay in device memory only long enough to verify the run, then they are discarded. Only the verification summary is stored.',
    disclaimerTitle: 'Health information',
    disclaimerBody:
        'Heart-rate, cadence, and coaching in ShareRun are exercise guidance, not medical care. They do not diagnose, treat, or prevent disease. Stop and talk to a clinician if you feel chest pain, dizziness, or anything else wrong.',
  ),
  'ja': _LegalPage(
    lang: 'ja',
    heading: '利用規約とプライバシーポリシー',
    termsTitle: '利用規約（必須）',
    termsBody:
        'ShareRunは検証済みのランニングと大会参加を提供します。寄付は走った距離に応じて運営者の名義で行われます。不正なランニングや決済の不正利用はアカウント制限の対象になります。',
    privacyTitle: 'プライバシーポリシー（必須）',
    privacyBody:
        'アカウントの識別情報、ランニング検証の結果、決済意図の記録をサービス提供のために処理します。心拍とケイデンスの生データはJenaの検証が終わるとすぐに破棄します。全文はプライバシーポリシーにあります。',
    locationTitle: '位置情報サービスの条項',
    locationBody:
        'ランニングの検証、クルーマップ、スタンプツアーのために位置情報を収集・利用します。同意を撤回すると、位置情報を使う機能が制限されることがあります。',
    healthTitle: '健康データの同意（任意・別途）',
    healthBody:
        'スマートウォッチ、HealthKit、Health Connectから読む心拍とケイデンスはランニングの検証にだけ使います。同意しなくてもアプリは使えます。同意がないとウォッチ連携と検証済みランニングの付与は制限されます。心拍の生配列はサーバーのデータベースに保存せず、検証の直後にメモリから消します。',
    sensorNote: '心拍とケイデンスの原データは端末のメモリで検証したあとすぐ破棄し、検証結果の要約だけを保存します。',
    disclaimerTitle: '健康情報について',
    disclaimerBody:
        'ShareRunの心拍・ケイデンス・コーチングは運動の参考情報であり、医療目的ではありません。病気の診断・治療・予防に代わるものではありません。胸の痛みやめまいを感じたら、すぐ運動をやめて医療者に相談してください。',
  ),
  'zh': _LegalPage(
    lang: 'zh-Hant',
    heading: '服務條款與隱私權政策',
    termsTitle: '服務條款（必填）',
    termsBody:
        'ShareRun 提供經過驗證的跑步與比賽參加。捐款以營運者的名義，依你跑過的距離進行。假跑步與付款濫用可能導致帳號受限。',
    privacyTitle: '隱私權政策（必填）',
    privacyBody:
        '為了提供服務，我們會處理帳號識別資料、跑步驗證結果，以及付款意圖紀錄。心率與步頻的原始資料在 Jena 驗證結束後立即捨棄。完整內容見隱私權政策。',
    locationTitle: '位置服務條款',
    locationBody: '為了驗證跑步、顯示隊伍地圖和進行印章行程，我們會蒐集並使用位置資訊。撤回同意後，依賴位置的功能可能受到限制。',
    healthTitle: '健康資料同意（選填，另行）',
    healthBody:
        '從智慧手錶、HealthKit 或 Health Connect 讀取的心率與步頻只用於驗證跑步。不同意也能使用 App。未同意時，手錶連結與已驗證跑步的累積會受到限制。心率原始陣列不會存進伺服器資料庫，驗證結束後會立刻從記憶體清除。',
    sensorNote: '心率與步頻的原始資料只在裝置記憶體中完成驗證，隨即捨棄。我們只保存驗證結果的摘要。',
    disclaimerTitle: '健康資訊說明',
    disclaimerBody:
        'ShareRun 的心率、步頻與指導是運動參考，不是醫療服務。不能取代疾病的診斷、治療或預防。如果感到胸痛、頭暈或其他不適，請立刻停止運動並諮詢醫療人員。',
  ),
  'es': _LegalPage(
    lang: 'es',
    heading: 'Términos del servicio y política de privacidad',
    termsTitle: 'Términos del servicio (obligatorio)',
    termsBody:
        'ShareRun ofrece carrera verificada y la inscripción a pruebas. Las donaciones, a nombre del operador, siguen la distancia que corres. Una carrera falsa o un abuso de pago pueden limitar la cuenta.',
    privacyTitle: 'Política de privacidad (obligatorio)',
    privacyBody:
        'Tratamos identificadores de la cuenta, resultados de verificación y registros de intención de pago para prestar el servicio. Las muestras crudas de pulso y cadencia se descartan en cuanto Jena termina la revisión. El texto completo está en la política de privacidad.',
    locationTitle: 'Términos del servicio de ubicación',
    locationBody:
        'La ubicación se recoge para verificar carreras, mostrar el mapa del crew y el recorrido de sellos. Si retiras el consentimiento, las funciones de ubicación pueden dejar de estar disponibles.',
    healthTitle: 'Consentimiento de datos de salud (opcional, aparte)',
    healthBody:
        'El pulso y la cadencia de un reloj, HealthKit o Health Connect se usan solo para verificar la carrera. Puedes usar la app sin consentir. Sin el consentimiento, vincular el reloj y el crédito de carrera verificada quedan limitados. Las series crudas de pulso no se guardan en la base de datos del servidor y se borran de la memoria justo después de la verificación.',
    sensorNote:
        'El pulso y la cadencia en bruto permanecen en la memoria del dispositivo solo el tiempo de la verificación y después se descartan. Solo se guarda el resumen de la verificación.',
    disclaimerTitle: 'Información de salud',
    disclaimerBody:
        'El pulso, la cadencia y la guía de ShareRun son orientación para el ejercicio, no atención médica. No diagnostican, tratan ni previenen enfermedades. Detente y consulta a un profesional si notas dolor en el pecho, mareo u otra molestia.',
  ),
  'pt': _LegalPage(
    lang: 'pt',
    heading: 'Termos de serviço e política de privacidade',
    termsTitle: 'Termos de serviço (obrigatório)',
    termsBody:
        'O ShareRun oferece corrida verificada e inscrição em provas. As doações, em nome do operador, seguem a distância que você corre. Corrida falsa e abuso de pagamento podem limitar a conta.',
    privacyTitle: 'Política de privacidade (obrigatório)',
    privacyBody:
        'Identificadores da conta, resultados da verificação e registros de intenção de pagamento são tratados para prestar o serviço. Amostras brutas de frequência cardíaca e cadência são descartadas assim que a Jena termina a checagem. O texto completo está na política de privacidade.',
    locationTitle: 'Termos do serviço de localização',
    locationBody:
        'A localização é coletada para verificar corridas, mostrar o mapa da crew e o passeio de carimbos. Se você retirar o consentimento, as funções de localização podem parar.',
    healthTitle: 'Consentimento de dados de saúde (opcional, separado)',
    healthBody:
        'Frequência cardíaca e cadência de um relógio, do HealthKit ou do Health Connect servem só para verificar a corrida. Dá para usar o app sem consentir. Sem o consentimento, vincular o relógio e o crédito da corrida verificada ficam limitados. As séries brutas de frequência cardíaca não vão para o banco do servidor e saem da memória logo após a verificação.',
    sensorNote:
        'Frequência cardíaca e cadência brutas ficam na memória do aparelho só o tempo da verificação e depois são descartadas. Só o resumo da verificação é guardado.',
    disclaimerTitle: 'Informação de saúde',
    disclaimerBody:
        'Frequência cardíaca, cadência e orientação no ShareRun são ajuda para o exercício, não cuidado médico. Não diagnosticam, tratam nem previnem doenças. Pare e fale com um profissional se sentir dor no peito, tontura ou qualquer outro mal-estar.',
  ),
  'de': _LegalPage(
    lang: 'de',
    heading: 'Nutzungsbedingungen und Datenschutzerklärung',
    termsTitle: 'Nutzungsbedingungen (erforderlich)',
    termsBody:
        'ShareRun bietet geprüfte Läufe und die Meldung zu Rennen. Spenden im Namen des Betreibers richten sich nach der gelaufenen Strecke. Gefälschte Läufe und Zahlungsmissbrauch können das Konto einschränken.',
    privacyTitle: 'Datenschutzerklärung (erforderlich)',
    privacyBody:
        'Kontokennungen, Prüfergebnisse und Zahlungsabsichten werden verarbeitet, um den Dienst zu betreiben. Rohdaten von Puls und Trittfrequenz werden gelöscht, sobald Jena die Prüfung beendet. Der volle Text steht in der Datenschutzerklärung.',
    locationTitle: 'Bedingungen für den Standortdienst',
    locationBody:
        'Der Standort wird erfasst, um Läufe zu prüfen, die Crew-Karte zu zeigen und die Stempel-Tour zu führen. Widerrufst du die Einwilligung, können Standortfunktionen entfallen.',
    healthTitle: 'Einwilligung zu Gesundheitsdaten (freiwillig, getrennt)',
    healthBody:
        'Puls und Trittfrequenz von Uhr, HealthKit oder Health Connect dienen nur der Laufprüfung. Die App lässt sich ohne Einwilligung nutzen. Ohne sie sind Uhrenverbindung und Gutschrift für geprüfte Läufe eingeschränkt. Rohe Pulsreihen werden nicht in der Server-Datenbank gespeichert und direkt nach der Prüfung aus dem Speicher gelöscht.',
    sensorNote:
        'Rohe Puls- und Trittfrequenzdaten bleiben nur für die Prüfung im Gerätespeicher und werden danach verworfen. Gespeichert wird nur die Zusammenfassung der Prüfung.',
    disclaimerTitle: 'Hinweis zur Gesundheit',
    disclaimerBody:
        'Puls, Trittfrequenz und Coaching in ShareRun sind Hinweise zum Training, keine medizinische Versorgung. Sie ersetzen nicht Diagnose, Behandlung oder Vorbeugung. Höre auf und sprich mit einer Ärztin oder einem Arzt, wenn du Brustschmerz, Schwindel oder etwas anderes Ungewöhnliches spürst.',
  ),
  'fr': _LegalPage(
    lang: 'fr',
    heading: 'Conditions d’utilisation et politique de confidentialité',
    termsTitle: 'Conditions d’utilisation (obligatoire)',
    termsBody:
        'ShareRun propose la course vérifiée et l’inscription aux épreuves. Les dons, au nom de l’opérateur, suivent la distance parcourue. Une course fictive ou un abus de paiement peut limiter le compte.',
    privacyTitle: 'Politique de confidentialité (obligatoire)',
    privacyBody:
        'Les identifiants du compte, les résultats de vérification et les intentions de paiement sont traités pour faire fonctionner le service. Les échantillons bruts de fréquence cardiaque et de cadence sont effacés dès que Jena a fini le contrôle. Le texte complet est dans la politique de confidentialité.',
    locationTitle: 'Conditions du service de localisation',
    locationBody:
        'La position est collectée pour vérifier les courses, afficher la carte du crew et le parcours des tampons. Si vous retirez votre consentement, les fonctions de localisation peuvent s’arrêter.',
    healthTitle: 'Consentement aux données de santé (facultatif, séparé)',
    healthBody:
        'La fréquence cardiaque et la cadence lues sur une montre, HealthKit ou Health Connect servent uniquement à vérifier la course. L’app reste utilisable sans consentement. Sans lui, lier la montre et le crédit de course vérifiée sont limités. Les séries brutes de fréquence cardiaque ne sont pas enregistrées dans la base du serveur et sont effacées de la mémoire juste après la vérification.',
    sensorNote:
        'La fréquence cardiaque et la cadence brutes restent en mémoire sur l’appareil le temps de la vérification, puis elles sont effacées. Seul le résumé de la vérification est conservé.',
    disclaimerTitle: 'Information de santé',
    disclaimerBody:
        'La fréquence cardiaque, la cadence et le coaching de ShareRun aident à l’exercice. Ce n’est pas un soin médical. Ils ne diagnostiquent, ne traitent et ne préviennent pas une maladie. Arrêtez-vous et parlez à un soignant si vous ressentez une douleur dans la poitrine, un vertige ou un autre malaise.',
  ),
  'vi': _LegalPage(
    lang: 'vi',
    heading: 'Điều khoản dịch vụ và chính sách quyền riêng tư',
    termsTitle: 'Điều khoản dịch vụ (bắt buộc)',
    termsBody:
        'ShareRun cung cấp chạy bộ đã xác minh và đăng ký giải. Khoản quyên góp đứng tên bên vận hành, theo quãng đường bạn chạy. Chạy giả và lạm dụng thanh toán có thể khiến tài khoản bị hạn chế.',
    privacyTitle: 'Chính sách quyền riêng tư (bắt buộc)',
    privacyBody:
        'Mã nhận dạng tài khoản, kết quả xác minh và bản ghi ý định thanh toán được xử lý để vận hành dịch vụ. Mẫu nhịp tim và cadence thô bị hủy ngay khi Jena kiểm tra xong. Toàn văn nằm trong chính sách quyền riêng tư.',
    locationTitle: 'Điều khoản dịch vụ vị trí',
    locationBody:
        'Vị trí được thu thập để xác minh buổi chạy, hiện bản đồ đội và tour đóng dấu. Nếu bạn rút đồng ý, các tính năng dùng vị trí có thể ngừng.',
    healthTitle: 'Đồng ý dữ liệu sức khỏe (tùy chọn, riêng)',
    healthBody:
        'Nhịp tim và cadence từ đồng hồ, HealthKit hoặc Health Connect chỉ dùng để xác minh buổi chạy. Bạn vẫn dùng được ứng dụng nếu không đồng ý. Không đồng ý thì liên kết đồng hồ và điểm chạy đã xác minh bị giới hạn. Chuỗi nhịp tim thô không được lưu trong cơ sở dữ liệu máy chủ và bị xóa khỏi bộ nhớ ngay sau khi xác minh.',
    sensorNote:
        'Nhịp tim và cadence thô chỉ ở trong bộ nhớ thiết bị đủ lâu để xác minh, rồi bị hủy. Chỉ phần tóm tắt kết quả xác minh được lưu.',
    disclaimerTitle: 'Thông tin sức khỏe',
    disclaimerBody:
        'Nhịp tim, cadence và hướng dẫn trong ShareRun là gợi ý tập luyện, không phải chăm sóc y tế. Chúng không chẩn đoán, điều trị hay phòng bệnh. Hãy dừng lại và hỏi nhân viên y tế nếu bạn đau ngực, chóng mặt hoặc thấy bất thường.',
  ),
  'th': _LegalPage(
    lang: 'th',
    heading: 'ข้อกำหนดการใช้บริการและนโยบายความเป็นส่วนตัว',
    termsTitle: 'ข้อกำหนดการใช้บริการ (จำเป็น)',
    termsBody:
        'ShareRun ให้บริการวิ่งที่ตรวจสอบแล้วและการสมัครแข่ง การบริจาคในนามผู้ดูแลเป็นไปตามระยะทางที่คุณวิ่ง การวิ่งปลอมและการใช้การชำระเงินในทางที่ผิดอาจทำให้บัญชีถูกจำกัด',
    privacyTitle: 'นโยบายความเป็นส่วนตัว (จำเป็น)',
    privacyBody:
        'ตัวระบุบัญชี ผลการตรวจสอบการวิ่ง และบันทึกความตั้งใจชำระเงินถูกประมวลผลเพื่อให้บริการ ข้อมูลดิบของชีพจรและเคเดนซ์จะถูกลบทันทีที่ Jena ตรวจเสร็จ ข้อความฉบับเต็มอยู่ในนโยบายความเป็นส่วนตัว',
    locationTitle: 'ข้อกำหนดบริการตำแหน่ง',
    locationBody:
        'ระบบเก็บตำแหน่งเพื่อตรวจสอบการวิ่ง แสดงแผนที่ครู และทัวร์แสตมป์ หากถอนความยินยอม ฟังก์ชันที่ใช้ตำแหน่งอาจหยุดทำงาน',
    healthTitle: 'ความยินยอมข้อมูลสุขภาพ (ไม่บังคับ แยกต่างหาก)',
    healthBody:
        'ชีพจรและเคเดนซ์จากนาฬิกา HealthKit หรือ Health Connect ใช้เพื่อตรวจสอบการวิ่งเท่านั้น ใช้แอปได้โดยไม่ยินยอม หากไม่ยินยอม การเชื่อมนาฬิกาและเครดิตการวิ่งที่ตรวจสอบแล้วจะถูกจำกัด แถวชีพจรดิบไม่ถูกเก็บในฐานข้อมูลเซิร์ฟเวอร์ และถูกลบจากหน่วยความจำทันทีหลังตรวจสอบ',
    sensorNote: 'ข้อมูลดิบของชีพจรและเคเดนซ์อยู่ในหน่วยความจำเครื่องเพียงช่วงตรวจสอบ แล้วถูกทิ้ง เก็บไว้เฉพาะสรุปผลการตรวจสอบ',
    disclaimerTitle: 'ข้อมูลสุขภาพ',
    disclaimerBody:
        'ชีพจร เคเดนซ์ และคำแนะนำใน ShareRun เป็นข้อมูลประกอบการออกกำลังกาย ไม่ใช่การรักษา ไม่ใช้วินิจฉัย รักษา หรือป้องกันโรค หากเจ็บหน้าอก เวียนหัว หรือรู้สึกผิดปกติ ให้หยุดและปรึกษาบุคลากรทางการแพทย์',
  ),
  'id': _LegalPage(
    lang: 'id',
    heading: 'Ketentuan layanan dan kebijakan privasi',
    termsTitle: 'Ketentuan layanan (wajib)',
    termsBody:
        'ShareRun menyediakan lari terverifikasi dan pendaftaran lomba. Donasi atas nama operator mengikuti jarak yang kamu lari. Lari palsu dan penyalahgunaan pembayaran dapat membatasi akun.',
    privacyTitle: 'Kebijakan privasi (wajib)',
    privacyBody:
        'Pengenal akun, hasil verifikasi lari, dan catatan maksud pembayaran diproses untuk menjalankan layanan. Sampel mentah detak jantung dan cadence dibuang begitu Jena selesai memeriksa. Teks lengkap ada di kebijakan privasi.',
    locationTitle: 'Ketentuan layanan lokasi',
    locationBody:
        'Lokasi dikumpulkan untuk memverifikasi lari, menampilkan peta kru, dan tur stempel. Jika kamu menarik persetujuan, fitur lokasi dapat berhenti.',
    healthTitle: 'Persetujuan data kesehatan (opsional, terpisah)',
    healthBody:
        'Detak jantung dan cadence dari jam, HealthKit, atau Health Connect hanya dipakai untuk memverifikasi lari. Aplikasi tetap bisa dipakai tanpa persetujuan. Tanpa persetujuan, tautan jam dan kredit lari terverifikasi menjadi terbatas. Deret detak jantung mentah tidak disimpan di basis data server dan dihapus dari memori segera setelah verifikasi.',
    sensorNote:
        'Detak jantung dan cadence mentah hanya ada di memori perangkat selama verifikasi, lalu dibuang. Yang disimpan hanya ringkasan verifikasi.',
    disclaimerTitle: 'Informasi kesehatan',
    disclaimerBody:
        'Detak jantung, cadence, dan panduan di ShareRun adalah bantuan latihan, bukan perawatan medis. Ini tidak mendiagnosis, mengobati, atau mencegah penyakit. Berhenti dan bicara dengan tenaga medis jika kamu merasa nyeri dada, pusing, atau ada yang tidak beres.',
  ),
};
