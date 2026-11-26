# 출시 노트 1.0.0 (버전 번호 +8)

Play Console "새로운 기능"에 붙여 넣는 글입니다. 11개 언어, 각 500자 이내(아래 숫자가 글자 수).
기부는 아직 송금 실적이 없어서 "기부 예정"으로만 씁니다. 기부처 이름은 쓰지 않습니다.

## +7 이후 main에 들어간 것 (확인한 근거)

운영 중인 +7은 `ac2e95e`(2026-11-04, #385)입니다. 그 뒤 main에 들어간 PR 중 **이용자 화면에 보이는 것**만 골랐습니다.

| 노트에 넣음 | 근거 PR | 앱 안에서 보이는 이름 |
|---|---|---|
| 친구 코드, 친구 달리기, 응원, 받은 응원 | #400~#403 | 마이페이지 > 친구, 친구 코드 만들기/입력, 친구 달리기, 박수·불꽃·파이팅·하트·최고, 받은 응원 |
| World Tour 13곳, 여권 스탬프 | #390, #391, #398, #404, #405 | 홈의 World Tour 카드, 여권 |
| 러닝 결과 화면의 거리·시간 | #397 | 러닝 결과 화면 |
| 공유 카드의 설치 QR | #396 | QR 넣기 스위치 |
| 구글 로그인 수정 | #387(이 브랜치에서 재적용: #406) | - |

노트에 **넣지 않은 것**:
- 의상 스킨(#386): 상점 판매가 막혀 있는지(결제 스위치) 이번에 확인하지 못해 뺐습니다. 확인되면 한 줄 추가하세요.
- 워치 앱(#388, #389)은 Wear OS 앱 별도 출시입니다. 폰 앱 노트에는 넣지 않았습니다.
- iOS(#394): 안드로이드 노트와 무관합니다.
- 마을 배경(#399): 화면에 연결하지 않았습니다.
- 응원 알림 끄기: 푸시 알림이 아직 없어서 설정을 노트에 쓰지 않았습니다.
- 서버 쪽 변경(계정 삭제 시 친구 데이터 정리 등)은 이용자에게 보이는 기능이 아니라서 뺐습니다.
- "기부 예정" 문구(+5~+6 노트에 있던 줄)는 500자 제한 때문에 이번 노트에서 뺐습니다. 스토어 설명문 11개 언어에는 그대로 들어 있습니다(`docs/store-listing-audit.md`). 넣고 싶으면 마지막 줄에 추가하되 글자 수를 확인하세요.

번역은 앱의 실제 문구(`remaining-ko-strings.json`, `app_localizations.dart`)에서 이름을 가져왔고, 문장은 원어민 검수 전입니다.


## 한국어 (ko-KR) — 256자
```text
친구: 마이페이지 > 친구에서 친구 코드를 만들어 보내거나 입력하면 친구가 돼요. 친구의 최근 7일 달리기(거리·시간·날짜)를 보고 박수·불꽃·파이팅·하트·최고로 응원해요. 받은 응원은 '받은 응원'에서 봐요.
World Tour: 인증한 러닝 거리로 에펠탑, 빅벤, 광화문 등 13곳을 가상 여행하고, 도착하면 여권에 스탬프가 찍혀요.
러닝 결과 화면에 거리와 시간이 나와요. 공유 카드에는 설치 QR이 들어가요.
구글 로그인이 되지 않던 문제를 고쳤어요.
```

## English (en-US) — 491자
```text
Friends: in My Page > Friends, create or enter a friend code to become friends. See friends' runs from the last 7 days and cheer with Clap, Fire, Go!, Heart or Great. Cheers you get are in Cheers received.
World Tour: use your verified run distance to travel virtually to 13 places such as the Eiffel Tower, Big Ben and more, and earn passport stamps.
The run result screen now shows distance and time. Share cards include an install QR.
Fixed an issue that prevented signing in with Google.
```

## 日本語 (ja-JP) — 276자
```text
フレンド: マイページ > フレンドで、フレンドコードを作って送る、または入力するとフレンドになれます。フレンドの直近7日間のラン(距離・時間・日付)を見て、拍手・炎・ファイト・ハート・最高で応援できます。もらった応援は「もらった応援」で見られます。
World Tour: 認証されたランの距離で、エッフェル塔・ビッグ・ベン・光化門など13か所をバーチャル旅行。到着するとパスポートにスタンプが押されます。
ランの結果画面に距離と時間が表示されます。シェアカードにはインストール用のQRが入ります。
Googleログインができない問題を修正しました。
```

## 繁體中文 (zh-TW) — 208자
```text
好友:在「我的主頁 > 好友」建立好友碼並傳給對方,或輸入好友碼就能成為好友。可查看好友最近7天的跑步(距離、時間、日期),並用鼓掌、火焰、加油、愛心、讚來加油。收到的加油在「收到的加油」查看。
World Tour:用已認證的跑步距離虛擬旅行13個地點,例如艾菲爾鐵塔、大笨鐘、光化門。抵達後護照會蓋上印章。
跑步結果畫面會顯示距離與時間。分享卡片會附上安裝 QR 碼。
修正了無法使用 Google 登入的問題。
```

## Español (es-ES) — 498자
```text
Amigos: en Mi Perfil > Amigos, crea o introduce un código de amigo para haceros amigos. Mira sus carreras de los últimos 7 días y anímalos con Aplauso, Fuego, ¡Ánimo!, Corazón o Genial.
World Tour: con la distancia de tus carreras verificadas viajas virtualmente a 13 lugares, como la Torre Eiffel y Big Ben, y consigues sellos en el pasaporte.
La pantalla de resultado muestra distancia y tiempo. Las tarjetas para compartir incluyen un QR de instalación.
Corregido el inicio de sesión con Google.
```

## Português (Brasil) (pt-BR) — 469자
```text
Amigos: em Meu Perfil > Amigos, crie ou digite um código de amigo para virarem amigos. Veja as corridas deles dos últimos 7 dias e torça com Palmas, Fogo, Força!, Coração ou Demais.
World Tour: com a distância das corridas verificadas, viaje virtualmente por 13 lugares, como Torre Eiffel e Big Ben, e ganhe carimbos no passaporte.
A tela de resultado mostra distância e tempo. Os cartões de compartilhamento incluem um QR de instalação.
Corrigido o login com o Google.
```

## Deutsch (de-DE) — 465자
```text
Freunde: Unter Mein Profil > Freunde einen Freundescode erstellen oder eingeben, um Freunde zu werden. Sieh ihre Läufe der letzten 7 Tage und feuere sie mit Applaus, Feuer, Los!, Herz oder Top an.
World Tour: Mit der Strecke deiner bestätigten Läufe reist du virtuell zu 13 Orten wie Eiffelturm und Big Ben und sammelst Stempel im Reisepass.
Der Ergebnisbildschirm zeigt Strecke und Zeit. Teilkarten enthalten einen Installations-QR.
Anmeldung mit Google repariert.
```

## Français (fr-FR) — 495자
```text
Amis : dans Mon Profil > Amis, créez ou saisissez un code ami pour devenir amis. Voyez leurs courses des 7 derniers jours et encouragez-les avec Applaudir, Feu, Courage !, Cœur ou Super.
World Tour : avec la distance de vos courses vérifiées, voyagez virtuellement dans 13 lieux, comme la tour Eiffel et Big Ben, et obtenez des tampons dans votre passeport.
L'écran de résultat affiche la distance et la durée. Les cartes à partager incluent un QR d'installation.
Connexion avec Google corrigée.
```

## Tiếng Việt (vi-VN) — 474자
```text
Bạn bè: trong Cá nhân > Bạn bè, tạo hoặc nhập mã bạn bè để kết bạn. Xem các buổi chạy của bạn bè trong 7 ngày gần nhất và cổ vũ bằng Vỗ tay, Lửa, Cố lên, Trái tim hoặc Tuyệt. Lời cổ vũ nhận được nằm trong Lời cổ vũ đã nhận.
World Tour: dùng quãng đường các buổi chạy đã xác thực để du lịch ảo tới 13 nơi như tháp Eiffel và Big Ben, và nhận dấu hộ chiếu.
Màn hình kết quả chạy hiển thị quãng đường và thời gian. Thẻ chia sẻ có mã QR cài đặt.
Đã sửa lỗi đăng nhập bằng Google.
```

## ภาษาไทย (th-TH) — 497자
```text
เพื่อน: ที่ โปรไฟล์ > เพื่อน สร้างรหัสเพื่อนแล้วส่งให้ หรือใส่รหัสเพื่อนเพื่อเป็นเพื่อนกัน ดูการวิ่งของเพื่อนใน 7 วันล่าสุด (ระยะทาง เวลา วันที่) และส่งกำลังใจด้วย ปรบมือ ไฟ สู้ ๆ หัวใจ หรือเยี่ยม กำลังใจที่ได้รับดูได้ที่ กำลังใจที่ได้รับ
World Tour: ใช้ระยะทางจากการวิ่งที่ผ่านการยืนยันเที่ยวเสมือนจริง 13 แห่ง เช่น หอไอเฟล บิ๊กเบน และควังฮวามุน เมื่อถึงที่หมายจะได้ตราประทับในพาสปอร์ต
หน้าผลการวิ่งแสดงระยะทางและเวลาแล้ว การ์ดแชร์มี QR สำหรับติดตั้ง
แก้ปัญหาที่ทำให้เข้าสู่ระบบด้วย Google ไม่ได้
```

## Bahasa Indonesia (id-ID) — 453자
```text
Teman: di Profil > Teman, buat atau masukkan kode teman untuk berteman. Lihat lari teman dalam 7 hari terakhir dan beri semangat dengan Tepuk tangan, Api, Semangat, Hati, atau Keren.
World Tour: gunakan jarak lari terverifikasi untuk berkeliling secara virtual ke 13 tempat, seperti Menara Eiffel dan Big Ben, dan dapatkan stempel paspor.
Layar hasil lari menampilkan jarak dan waktu. Kartu berbagi menyertakan QR instal.
Login dengan Google diperbaiki.
```
