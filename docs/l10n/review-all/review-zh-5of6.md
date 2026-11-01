# 번역 검수 요청 — 쉐어런 (Traditional Chinese (Taiwan)) · 파트 5/6

아래는 한국어 앱 "쉐어런"(걷기·달리기 앱, 회사 자금 기부 연계)의 화면 문구를 Traditional Chinese (Taiwan)(으)로 번역한 것입니다.
원어민 시각에서 검수해 주세요.

검수 기준:
1. 오역과 누락
2. 어색하거나 그 나라에서 쓰지 않는 표현
3. 한국어에 없는 약속·단정이 들어간 곳 (특히 기부, 보상, 환불, 탈퇴 관련)
4. 숫자·금액·고유명사가 원문과 다른 곳
5. "운영자(회사 또는 운영 주체)"를 그 나라에서 오해 없는 말로 옮겼는지

지켜야 할 것:
- SHARE, DIA, VALUE, Coach+, ShareRun은 번역하지 않습니다.
- `${...}`, `{...}` 같은 자리표시자는 그대로 두어야 합니다.
- 기부는 "이미 했다"가 아니라 "할 예정"이라는 뜻이어야 합니다.
- 앱 화면 문구이므로 짧고 친절하게.

출력 형식 (문제가 있는 항목만, 표로):
| ID | 원문(한국어) | 현재 번역 | 문제 | 고친 문장 |
문제가 없는 항목은 적지 말고, 마지막에 "문제 없음: N개"라고만 적어 주세요.

---
[running_crew.body.43]
KO: ${mine.crew.name} · ${mine.members.length}명
ZH: ${mine.crew.name} · ${mine.members.length}人

[running_crew.body.44]
KO: 부크루장 해제
ZH: 解除副隊長

[running_crew.body.45]
KO: 부크루장으로
ZH: 設為副隊長

[running_crew.body.46]
KO: 신고하기
ZH: 進行檢舉

[running_crew.body.47]
KO: 가입 신청 ${requests.length}건
ZH: 加入申請 ${requests.length} 件

[running_crew.body.48]
KO: 기다리는 신청이 없어요.
ZH: 沒有等待審核的申請。

[running_crew.body.49]
KO: "${mine.crew.name}" 크루를 없애요.
크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
ZH: 即將解散「${mine.crew.name}」Crew。
身為隊長的我也會一起退出。
已購買的徽章也會消失，且無法復原。

$note

[running_crew.body.5]
KO: 신청
ZH: 申請

[running_crew.body.6]
KO: "$name"(으)로 바꾸면 $cost DIA가 들어요. 보너스 DIA를 먼저 써요.
ZH: 變更為「$name」將花費 $cost DIA。將優先使用贈送 DIA。

[running_crew.body.7]
KO: 크루 없애기
ZH: 解散 Crew

[running_crew.body.8]
KO: "${mine.crew.name}" 크루를 없애요.
${others > 0 ?
ZH: 將解散「${mine.crew.name}」Crew。
${others > 0 ?

[running_crew.body.9]
KO: "${mine.crew.name}" 크루를 없애요.
크루원 $others명도 모두 크루에서 나오고, 크루장인 나도 함께 크루에서 나와요.
산 엠블럼도 사라지고 되돌릴 수 없어요.

$note
ZH: 即將解散「${mine.crew.name}」Crew。
$others 位成員也會一起退出 Crew，身為隊長的我也會一起退出。
已購買的徽章也會消失，且無法復原。

$note

[running_crew.button]
KO: 크루 만들기
ZH: 建立 Crew

[running_crew.button.10]
KO: 받기
ZH: 接受

[running_crew.button.2]
KO: 서버가 50 DIA 또는 30,000 SHARE 중 선택한 금액만 차감합니다.
ZH: 伺服器僅會扣除所選金額：50 DIA 或 30,000 SHARE。

[running_crew.button.3]
KO: 가입 방식
ZH: 加入方式

[running_crew.button.4]
KO: 자유 가입
누구나 바로 들어와요
ZH: 自由加入
任何人皆可立即加入

[running_crew.button.5]
KO: 승인 가입
신청을 받아 크루장이 정해요
ZH: 審核加入
由隊長審核申請後決定

[running_crew.button.6]
KO: 검색
ZH: 搜尋

[running_crew.button.7]
KO: 신고
ZH: 檢舉

[running_crew.button.8]
KO: 신청 취소
ZH: 取消申請

[running_crew.button.9]
KO: 거절
ZH: 拒絕

[running_crew.dialog]
KO: 크루 이름 바꾸기
ZH: 變更 Crew 名稱

[running_crew.dialog.2]
KO: 다음
ZH: 下一步

[running_crew.hint]
KO: 크루 검색
ZH: 搜尋 Crew

[running_crew.hint.2]
KO: 크루 이름 입력
ZH: 輸入 Crew 名稱

[running_crew.hint.3]
KO: 초기화
ZH: 重設

[running_crew.hint.4]
KO: 2~20자로 지어 주세요
ZH: 請設定 2~20 個字元

[running_crew.label]
KO: ${crew.memberCount}/${crew.maxMembers}명${crew.needsApproval ?
ZH: ${crew.memberCount}/${crew.maxMembers}人${crew.needsApproval ?

[running_crew.toast]
KO: 로그인한 뒤에 다시 시도해 주세요.
ZH: 請登入後重試。

[running_crew.toast.10]
KO: 유료 엠블럼은 크루장만 살 수 있어요.
ZH: 僅 Crew 隊長可購買付費徽章。

[running_crew.toast.11]
KO: 이미 크루가 가진 엠블럼이에요.
ZH: Crew 已擁有此徽章。

[running_crew.toast.12]
KO: 엠블럼을 사지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 購買徽章失敗，請稍後再試。

[running_crew.toast.13]
KO: 엠블럼은 자주 바꿀 수 없어요. 잠시 뒤에 다시 바꿔 주세요.
ZH: 徽章無法頻繁變更，請稍後再試。

[running_crew.toast.14]
KO: 아직 쓸 수 없는 테두리나 엠블럼이에요.
ZH: 此外框或徽章尚未開放使用。

[running_crew.toast.15]
KO: 엠블럼을 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 變更徽章失敗，請稍後再試。

[running_crew.toast.16]
KO: 이 폰에만 저장했어요. 서버에 크루가 생기면 함께 저장돼요.
ZH: 僅儲存於此手機。伺服器建立 Crew 時將一併儲存。

[running_crew.toast.17]
KO: 크루 엠블럼을 바꿨어요.
ZH: 已變更 Crew 徽章。

[running_crew.toast.18]
KO: 가입
ZH: 加入

[running_crew.toast.19]
KO: "${crew.name}" 크루에 가입했어요.
ZH: 已加入「${crew.name}」Crew。

[running_crew.toast.2]
KO: 새 크루 창설 완료 (−$_createCrewDiaCost DIA)
ZH: 已建立新 Crew（−$_createCrewDiaCost DIA）

[running_crew.toast.20]
KO: 가입을 신청했어요. 승인되면 크루원이 돼요.
ZH: 已送出加入申請。經核准後即可成為成員。

[running_crew.toast.21]
KO: 이미 다른 크루에 있거나 신청해 둔 곳이 있거나 인원이 가득 찼어요.
ZH: 您已在其他 Crew、已有申請紀錄，或該 Crew 已滿員。

[running_crew.toast.22]
KO: 이 크루에는 들어갈 수 없어요.
ZH: 無法加入此 Crew。

[running_crew.toast.23]
KO: 가입하지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 加入失敗，請稍後再試。

[running_crew.toast.24]
KO: 가입 신청을 거뒀어요.
ZH: 已撤回加入申請。

[running_crew.toast.25]
KO: 거두지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 撤回失敗，請稍後再試。

[running_crew.toast.26]
KO: 자유 가입으로 바꿨어요.
ZH: 已變更為自由加入。

[running_crew.toast.27]
KO: 승인 가입으로 바꿨어요.
ZH: 已變更為審核加入。

[running_crew.toast.28]
KO: 크루 이름을 "$name"(으)로 바꿨어요.
ZH: 已將 Crew 名稱變更為「$name」。

[running_crew.toast.29]
KO: 신청 목록을 불러오지 못했어요.
ZH: 無法載入申請列表。

[running_crew.toast.3]
KO: 새 크루 창설 완료 (−$_createCrewShareCost SHARE)
ZH: 已建立新 Crew（−$_createCrewShareCost SHARE）

[running_crew.toast.30]
KO: ${request.nickname}님을 받았어요.
ZH: 已批准 ${request.nickname} 的申請。

[running_crew.toast.31]
KO: ${request.nickname}님의 신청을 거절했어요.
ZH: 已拒絕 ${request.nickname} 的申請。

[running_crew.toast.32]
KO: 이미 다른 크루에 있거나 인원이 가득 찼어요.
ZH: 已在其他 Crew 或該 Crew 已滿員。

[running_crew.toast.33]
KO: 처리하지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 處理失敗，請稍後再試。

[running_crew.toast.34]
KO: 크루를 없앴어요.
ZH: 已解散 Crew。

[running_crew.toast.35]
KO: 없애지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 解散失敗，請稍後再試。

[running_crew.toast.36]
KO: 크루 나가기
ZH: 退出 Crew

[running_crew.toast.37]
KO: "${mine.crew.name}" 크루에서 나갈까요? 다시 가입할 수 있어요.
ZH: 確定要退出「${mine.crew.name}」Crew 嗎？日後仍可重新加入。

[running_crew.toast.38]
KO: 나가기
ZH: 退出

[running_crew.toast.39]
KO: 크루에서 나왔어요.
ZH: 已退出 Crew。

[running_crew.toast.4]
KO: 크루 창설 실패: $error
ZH: 建立 Crew 失敗：$error

[running_crew.toast.40]
KO: 크루장은 나갈 수 없어요.
ZH: 隊長無法退出隊伍。

[running_crew.toast.41]
KO: 나가지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 退出失敗，請稍後再試。

[running_crew.toast.42]
KO: 지금은 신고할 수 없어요.
ZH: 目前無法檢舉。

[running_crew.toast.43]
KO: 신고했어요. 운영자가 확인할게요.
ZH: 已送出檢舉，管理員將進行審核。

[running_crew.toast.44]
KO: 신고하지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 檢舉失敗，請稍後再試。

[running_crew.toast.45]
KO: 크루장 넘기기
ZH: 移交隊長職位

[running_crew.toast.46]
KO: ${member.nickname}님이 새 크루장이에요.
ZH: ${member.nickname} 成為了新隊長。

[running_crew.toast.47]
KO: 넘기지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 移交失敗，請稍後再試。

[running_crew.toast.48]
KO: ${member.nickname}님을 부크루장으로 했어요.
ZH: 已將 ${member.nickname} 設為副隊長。

[running_crew.toast.5]
KO: 전체 랭킹을 표시합니다.
ZH: 顯示全體排名。

[running_crew.toast.6]
KO: "$result" 검색 결과를 표시합니다.
ZH: 顯示「$result」的搜尋結果。

[running_crew.toast.7]
KO: 크루에 들어가면 크루 룸을 볼 수 있어요.
ZH: 加入 Crew 後即可查看 Crew 聊天室。

[running_crew.toast.8]
KO: 엠블럼은 자주 바꿀 수 없어요. 약 $days일 뒤에 다시 바꿀 수 있어요.
ZH: 徽章無法頻繁變更。大約 $days 天後即可再次變更。

[running_crew.toast.9]
KO: DIA가 부족해요.
ZH: DIA 不足。

[security_privacy_center.body]
KO: 적립 규칙, 내 거래 내역, 기부 정산, 기록 이의 신청을 한곳에서 확인해요.
ZH: 集中查看積分規則、交易紀錄、捐款結算與紀錄申訴。

[security_privacy_center.body.2]
KO: 서버 원장에 기록된 지급·사용 내역
ZH: 記錄於伺服器總帳的發放與使用紀錄

[security_privacy_center.body.3]
KO: 기부 정산
ZH: 捐款結算

[security_privacy_center.body.4]
KO: 내가 기여한 금액 · 이번 달 기부
ZH: 我的貢獻金額 · 本月捐款

[security_privacy_center.body.5]
KO: 로그인된 기기
ZH: 已登入的裝置

[security_privacy_center.body.6]
KO: 내 계정을 연 기기 · 모든 기기에서 로그아웃
ZH: 登入我帳戶的裝置 · 從所有裝置登出

[security_privacy_center.body.7]
KO: 기록 소명 및 고객센터
ZH: 紀錄申訴與客服中心

[security_privacy_center.body.8]
KO: 검증 결과에 이의가 있을 때
ZH: 對驗證結果有異議時

[share_dia_exchange.body]
KO: 이번 주 남은 한도 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA
ZH: 本週剩餘額度 ${quote.remainingDia} / ${quote.weeklyCapDia} DIA

[share_dia_exchange.body.2]
KO: ${quote.unitDia} DIA 단위 · 교환 가능 SHARE ${quote.spendableShare}
ZH: 以 ${quote.unitDia} DIA 為單位 · 可兌換 SHARE ${quote.spendableShare}

[share_dia_exchange.body.3]
KO: 추천 보상 잠금 ${quote.lockedShare} SHARE
ZH: 推薦獎勵已鎖定 ${quote.lockedShare} SHARE

[share_dia_exchange.button]
KO: SHARE → DIA 교환
ZH: SHARE → DIA 兌換

[share_dia_exchange.button.2]
KO: DIA 팩 · 준비 중
ZH: DIA 包 · 準備中

[share_dia_exchange.button.3]
KO: 교환 중...
ZH: 兌換中...

[share_dia_exchange.button.4]
KO: 교환
ZH: 兌換

[share_dia_exchange.toast]
KO: ${result.rateSharePerDia} SHARE = 1 DIA 교환이 반영되었습니다.
ZH: 已完成 ${result.rateSharePerDia} SHARE = 1 DIA 的兌換。

[shop.accessory_shop_grid.body]
KO: 아직 준비 중이에요
ZH: 尚在準備中

[shop.accessory_shop_grid.body.2]
KO: ${accessory.tierLock!.labelKo} 티어
ZH: ${accessory.tierLock!.labelKo} 階級

[shop.accessory_shop_grid.button]
KO: 가격은 바뀔 수 있어요.
ZH: 價格可能會有所變動。

[shop.accessory_shop_grid.button.2]
KO: 입혀 보기
ZH: 試穿

[shop.accessory_shop_grid.button.3]
KO: 벗기
ZH: 脫下

[shop.accessory_shop_grid.button.4]
KO: 입기
ZH: 穿上

[shop.accessory_shop_grid.button.5]
KO: ${a.tierLock!.labelKo} 티어가 되면 살 수 있어요
ZH: 達到 ${a.tierLock!.labelKo} 階級即可購買

[shop.accessory_shop_grid.button.6]
KO: 사기 · ${a.priceLabel}
ZH: 購買 · ${a.priceLabel}

[shop.accessory_shop_grid.button.7]
KO: 티어 보상이에요
ZH: 這是階級獎勵

[shop.accessory_shop_grid.toast]
KO: 서버에 연결되면 살 수 있어요.
ZH: 連線至伺服器後即可購買。

[shop.accessory_shop_grid.toast.2]
KO: }가 모자라거나 이미 가진 소품이에요.
ZH: }不足或已擁有該配件。

[shop.accessory_shop_grid.toast.3]
KO: 아직 티어가 모자라요.
ZH: 階級還不夠。

[shop.accessory_shop_grid.toast.4]
KO: 사지 못했어요. 잠시 뒤 다시 해 주세요.
ZH: 購買失敗。請稍後再試。

[shop.battle_pass_grant.body]
KO: 시즌 1 프레임
ZH: 第 1 季頭像框

[shop.battle_pass_grant.body.2]
KO: 시즌 1 배지
ZH: 第 1 季徽章

[shop.battle_pass_grant.body.3]
KO: 시즌 1 플러스 프레임
ZH: 第 1 季 Plus 外框

[shop.battle_pass_grant.body.4]
KO: 시즌 1 스킨
ZH: 第 1 季造型

[shop.battle_pass_grant.body.5]
KO: 시즌 1 플러스 배지
ZH: 第 1 季 Plus 徽章

[shop.cosmetics_catalog.body]
KO: 러닝화 스킨
ZH: 跑鞋造型

[shop.cosmetics_catalog.body.2]
KO: 결과 카드 프레임
ZH: 結果卡外框

[shop.friend_ghost_run.body]
KO: ${AppStrings.storeItemFriendGhost} · 보유 $count
ZH: ${AppStrings.storeItemFriendGhost} · 擁有 $count

[shop.friend_ghost_run.body.2]
KO: 비교 시작
ZH: 開始比較

[shop.friend_ghost_run.hint]
KO: 친구 아이디
ZH: 好友 ID

[shop.friend_ghost_run.hint.2]
KO: 기록 아이디
ZH: 紀錄 ID

[shop.friend_ghost_run.toast]
KO: 친구 고스트 페이스 보유량이 없습니다. 상점에서 구매해 주세요.
ZH: 您沒有好友幽靈配速。請至商店購買。

[shop.friend_ghost_run.toast.2]
KO: 친구 고스트 ${formatPaceSecPerKm(pace)}
ZH: 好友幽靈 ${formatPaceSecPerKm(pace)}

[shop.friend_ghost_run.toast.3]
KO: 내 최고 기록 비교는 무료입니다. 티켓을 쓰지 않았습니다.
ZH: 與個人最佳紀錄比較是免費的。未扣除票券。

[shop.friend_ghost_run.toast.4]
KO: 친구 기록을 확인하지 못했습니다.
ZH: 無法查看好友的紀錄。

[shop.friend_ghost_run.toast.5]
KO: 친구 고스트를 사용하지 못했습니다.
ZH: 無法使用好友幽靈。

[shop.server_item_use_button.body]
KO: ${widget.label} · 보유 $count
ZH: ${widget.label} · 持有 $count

[shop.server_item_use_button.button]
KO: ${widget.label} · 보유 $shown/$cap
ZH: ${widget.label} · 持有 $shown/$cap

[shop.server_item_use_button.toast]
KO: ${widget.label} 보유량이 없습니다.
ZH: 沒有持有的 ${widget.label}。

[shop.server_item_use_button.toast.2]
KO: ${widget.label} 사용 완료
ZH: 已使用 ${widget.label}

[shop.server_item_use_button.toast.3]
KO: ${widget.label} 을 사용하지 못했습니다.
ZH: 未能使用 ${widget.label}。

[shop.store_look.body]
KO: 심박·상황에 맞춘 심층 코칭
ZH: 依據心率與狀況量身打造的深入指導

[shop.store_look.body.2]
KO: 월간
ZH: 按月

[shop.store_look.body.3]
KO: 연간
ZH: 按年

[shop.store_look.body.4]
KO: 보관함 $owned
ZH: 保管箱 $owned

[shop.streak_item_message.body]
KO: 세이프가드는 최대 2개까지 보유할 수 있습니다.
ZH: 防護盾最多可持有 2 個。

[shop.streak_item_message.body.10]
KO: 그 기록에는 페이스가 없습니다.
ZH: 該記錄沒有配速資料。

[shop.streak_item_message.body.11]
KO: 10회 묶음은 한 장씩 사용합니다.
ZH: 10 張組合為逐張使用。

[shop.streak_item_message.body.12]
KO: 이미 보유한 코스메틱입니다.
ZH: 已擁有該裝飾品。

[shop.streak_item_message.body.13]
KO: 이번 시즌에 판매하지 않는 아이템입니다.
ZH: 此道具本賽季不販售。

[shop.streak_item_message.body.14]
KO: 보유한 뒤에 장착할 수 있습니다.
ZH: 取得後即可裝備。

[shop.streak_item_message.body.15]
KO: 코스메틱은 사용해서 사라지지 않습니다.
ZH: 裝飾品不會因使用而消耗。

[shop.streak_item_message.body.2]
KO: 심폐소생권은 한 달에 2번까지 사용할 수 있습니다.
ZH: 復活券每月最多可使用 2 次。

[shop.streak_item_message.body.3]
KO: 되돌릴 끊긴 스트릭이 없습니다.
ZH: 沒有已中斷的連續記錄可恢復。

[shop.streak_item_message.body.4]
KO: 스트릭이 끊긴 지 72시간이 지나 되돌릴 수 없습니다.
ZH: 連續記錄中斷已超過 72 小時，無法恢復。

[shop.streak_item_message.body.5]
KO: 막을 빠진 날이 없습니다.
ZH: 沒有缺席的日子需要填補。

[shop.streak_item_message.body.6]
KO: 추가 참가권은 대회에 참가할 때 사용됩니다.
ZH: 額外參賽券用於參加比賽。

[shop.streak_item_message.body.7]
KO: 친구 기록을 찾지 못했습니다.
ZH: 找不到好友的記錄。

[shop.streak_item_message.body.8]
KO: 그 기록은 선택한 친구의 기록이 아닙니다.
ZH: 該記錄並非所選好友的記錄。

[shop.streak_item_message.body.9]
KO: 검증되지 않은 기록과는 비교할 수 없습니다.
ZH: 無法與未驗證的記錄進行比較。

[app.watchSyncApple]
KO: Apple 건강 연동하기
ZH: 連結 Apple 健康

[app.watchSyncComplete]
KO: 연동 완료하고 시작하기
ZH: 完成連結並開始

[app.watchSyncExternalDevices]
KO: 가민, 순토, 코로스 등 외부 전문 기기를 사용하시나요?
ZH: 您有使用 Garmin、Suunto、COROS 等外部專業設備嗎？

[app.watchSyncGoogle]
KO: Google Health Connect 연동하기
ZH: 連結 Google Health Connect

[app.watchSyncSkip]
KO: 건너뛰기
ZH: 略過

[app.watchSyncSubtitle]
KO: 러닝 검증을 위해 심박수와 걸음 수 데이터가 필요합니다.
ZH: 跑步驗證需要心率與步數資料。

[app.watchSyncTitle]
KO: 정확한 기록 측정을 위해
스마트워치를 연결해 주세요.
ZH: 為了準確記錄測量數據，
請連接智慧手錶。

[snail_faq.body]
KO: 지금은 값을 불러오지 못했어요. 연결된 뒤에 다시 물어봐 주세요.
ZH: 目前無法讀取資料。連線後請再試一次。

[snail_to_cheetah_book.body]
KO: 티어 도감
ZH: 階級圖鑑

[snail_to_cheetah_book.body.10]
KO: 달팽이 (Unrated)
ZH: 蝸牛 (Unrated)

[snail_to_cheetah_book.body.11]
KO: 등급 배정 전 임시 등급
ZH: 評級分配前的臨時階級

[snail_to_cheetah_book.body.13]
KO: 빠른 걸음 및 기초 체력 형성 단계
ZH: 快走及基礎體能培養階段

[snail_to_cheetah_book.body.14]
KO: 평균 페이스 7분 30초 이상
ZH: 平均配速 7 分 30 秒以上

[snail_to_cheetah_book.body.15]
KO: 가벼운 조깅을 즐기는 러닝 입문자
ZH: 享受輕鬆慢跑的跑步初學者

[snail_to_cheetah_book.body.16]
KO: 평균 페이스 6분 00초 ~ 7분 29초
ZH: 平均配速 6 分 00 秒～7 分 29 秒

[snail_to_cheetah_book.body.17]
KO: 일반 동호인 / 표준 그룹
ZH: 一般跑步愛好者／標準組

[snail_to_cheetah_book.body.18]
KO: 평균 페이스 5분 00초 ~ 5분 59초
ZH: 平均配速 5 分 00 秒～5 分 59 秒

[snail_to_cheetah_book.body.19]
KO: 러닝 숙련자 수준
ZH: 進階跑者水準

[snail_to_cheetah_book.body.2]
KO: 달릴수록 새로운 친구를 만나요
ZH: 跑得越多，遇見的新朋友也越多

[snail_to_cheetah_book.body.20]
KO: 평균 페이스 4분 00초 ~ 4분 59초
ZH: 平均配速 4 分 00 秒～4 分 59 秒

[snail_to_cheetah_book.body.21]
KO: 아마추어 최상위권 수준
ZH: 業餘頂尖水準

[snail_to_cheetah_book.body.22]
KO: 평균 페이스 4분 00초 미만
ZH: 平均配速 4 分 00 秒以內

[snail_to_cheetah_book.body.3]
KO: 25단계 연대기
ZH: 25階段編年史

[snail_to_cheetah_book.body.4]
KO: 달팽이부터 치타까지 모든 등급을 열람할 수 있어요. 카드를 누르면 액세서리를 입혀 볼 수 있어요.
ZH: 可查看從蝸牛到獵豹的所有階級。點擊卡片即可試穿配件。

[snail_to_cheetah_book.body.5]
KO: 완료
ZH: 已完成

[snail_to_cheetah_book.body.6]
KO: 현재
ZH: 目前

[snail_to_cheetah_book.body.7]
KO: 도전
ZH: 挑戰

[snail_to_cheetah_book.body.8]
KO: 아직 티어가 없어요
ZH: 目前尚無階級

[snail_to_cheetah_book.body.9]
KO: 첫 달리기가 심사되면 티어가 정해지고
옷과 소품을 입힐 수 있어요
ZH: 首次跑步完成審核後即會決定等級，
並可為其穿戴服飾與配件

[snail_to_cheetah_book.button]
KO: 달리러 가기
ZH: 去跑步

[solo_pedometer.body]
KO: 등급 목표 달성률: $percent%
ZH: 等級目標達成率：$percent%

[solo_pedometer.body.10]
KO: 줍기 대기 : $pendingCoinsInt SHARE
ZH: 待收取：$pendingCoinsInt SHARE

[solo_pedometer.body.11]
KO: 워킹챌린지 혜택 알림 받는 중 🔔
ZH: 正在接收健走挑戰福利通知 🔔

[solo_pedometer.body.12]
KO: 혜택 알림이 완전히 꺼져 있습니다 🔕
ZH: 福利通知已完全關閉 🔕

[solo_pedometer.body.13]
KO: 알림 해지
ZH: 取消通知

[solo_pedometer.body.14]
KO: 알림 받기
ZH: 開啟通知

[solo_pedometer.body.15]
KO: 월
ZH: 週一

[solo_pedometer.body.16]
KO: 화
ZH: 週二

[solo_pedometer.body.17]
KO: 수
ZH: 週三

[solo_pedometer.body.18]
KO: 목
ZH: 週四

[solo_pedometer.body.19]
KO: 금
ZH: 週五

[solo_pedometer.body.2]
KO: 등급 목표 달성 · 만보 달성!
ZH: 達成等級目標 · 達到萬步！

[solo_pedometer.body.20]
KO: 토
ZH: 週六

[solo_pedometer.body.21]
KO: 일
ZH: 週日

[solo_pedometer.body.22]
KO: 이번 주 분석 일지
ZH: 本週分析日誌

[solo_pedometer.body.23]
KO: 날짜를 선택하면 그날의 걸음 수가 표시됩니다.
ZH: 選擇日期即可顯示該天的步數。

[solo_pedometer.body.24]
KO: ${selected.month}월 ${selected.day}일의 누적 걸음수: ${_comma(displaySelectedSteps)}보
ZH: ${selected.month} 月 ${selected.day} 日累積步數：${_comma(displaySelectedSteps)} 步

[solo_pedometer.body.3]
KO: 등급 목표 달성! 만보까지 ${comma(left)}걸음
ZH: 達成等級目標！距離萬步還差 ${comma(left)} 步

[solo_pedometer.body.4]
KO: 아직 주울 SHARE가 없어요. 조금 더 걸어보세요.
ZH: 尚無可收取的 SHARE，再多走幾步吧。

[solo_pedometer.body.5]
KO: 워킹챌린지
ZH: 健走挑戰

[solo_pedometer.body.6]
KO: [${running.koreanName}] 산책 중
ZH: [${running.koreanName}] 散步中

[solo_pedometer.body.7]
KO: 내 누적 SHARE 통장 🏦
ZH: 我的累積 SHARE 存摺 🏦

[solo_pedometer.body.8]
KO: 오늘의 땀방울 : $todayCollectedCoins / ${PedometerHarvestLedger.dailyShareCap} SHARE 🪙
ZH: 今天的汗水：$todayCollectedCoins / ${PedometerHarvestLedger.dailyShareCap} SHARE 🪙

[solo_pedometer.body.9]
KO: 걸음
ZH: 步

[solo_pedometer.button]
KO: 나중에
ZH: 稍後

[solo_pedometer.button.2]
KO: 계속
ZH: 繼續

[solo_pedometer.dialog]
KO: 걸음 수를 세려면 권한이 필요해요
ZH: 計算步數需要權限

[solo_pedometer.dialog.2]
KO: • 신체 활동: 폰이 센 걸음 수를 읽습니다.
• 건강 데이터(걸음): Health Connect에 기록된 걸음 수를 읽어 화면이 꺼져 있을 때의 걸음도 반영합니다.

걸음 수는 보상 계산에만 쓰이고, 동의하지 않아도 다른 기능은 쓸 수 있어요.
ZH: • 身體活動：讀取手機偵測到的步數。
• 健康資料（步數）：讀取 Health Connect 中記錄的步數，連螢幕關閉時的步數也會納入。

步數僅用於計算獎勳，即使不同意，其他功能仍可使用。

[solo_pedometer.toast]
KO: SHARE를 줍는 중이에요. 잠시만 기다려 주세요.
ZH: 正在收取 SHARE，請稍候。

[solo_pedometer.toast.2]
KO: SHARE 줍기에 실패했습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.
ZH: 收取 SHARE 失敗。請檢查網路連線後重試。

[sponsor.sponsor_billboard.body]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요
ZH: 預計每完成 1 公里驗證跑步，就捐出 100 韓元

[sponsor_payment.body]
KO: 결제 준비 중...
ZH: 正在準備付款...

[sponsor_payment.body.2]
KO: 결제 진행하기
ZH: 進行付款

[sponsor_payment.body.3]
KO: 후원 결제
ZH: 贊助付款

[sponsor_payment.hint]
KO: 후원 금액
ZH: 贊助金額

[sponsor_payment.title]
KO: 대회 후원
ZH: 賽事贊助

[sponsor_payment.toast]
KO: 스폰서 결제가 대회에 반영되었습니다.
ZH: 贊助付款已反映至賽事中。

[sponsor_payment.toast.2]
KO: 후원 결제에 실패했어요: $error
ZH: 贊助付款失敗：$error

[stamp.stamp_tour_provider.body]
KO: 우리 동네 랜드마크 스탬프 찍기 ($officialVisitedCount/${officialLandmarks.length})
ZH: 收集本地地標集章 ($officialVisitedCount/${officialLandmarks.length})

[stamp.stamp_tour_provider.body.10]
KO: 오늘의 1km 걷기 미션을 이미 완료했습니다.
ZH: 已完成今天的 1 公里健走任務。

[stamp.stamp_tour_provider.body.11]
KO: 1km 걷기 미션 완료! ${AppStrings.stampTourOfficialDiaPending}
ZH: 1公里步行任務完成！${AppStrings.stampTourOfficialDiaPending}

[stamp.stamp_tour_provider.body.12]
KO: 아직 ${remain.toStringAsFixed(2)}km 더 걸어주세요.
ZH: 請再步行 ${remain.toStringAsFixed(2)} 公里。

[stamp.stamp_tour_provider.body.13]
KO: 공식 DIA 대기 기록에 실패했습니다.
ZH: 記錄官方 DIA 待發放狀態失敗。

[stamp.stamp_tour_provider.body.2]
KO: 위치 권한이 필요합니다. 설정에서 허용해 주세요.
ZH: 需要位置權限。請在設定中允許。

[stamp.stamp_tour_provider.body.3]
KO: GPS 수신 중 오류가 발생했습니다.
ZH: 接收 GPS 時發生錯誤。

[stamp.stamp_tour_provider.body.4]
KO: 위치 추적을 시작할 수 없습니다.
ZH: 無法開始位置追蹤。

[stamp.stamp_tour_provider.body.5]
KO: 모든 공식 랜드마크 스탬프를 이미 획득했습니다.
ZH: 已獲得所有官方地標集章。

[stamp.stamp_tour_provider.body.6]
KO: 현재 위치를 확인할 수 없습니다. 위치 권한을 허용해 주세요.
ZH: 無法確認目前位置。請允許位置權限。

[stamp.stamp_tour_provider.body.7]
KO: 목표 랜드마크 반경 50m 이내로 접근해 주세요.
ZH: 請移動至目標地標半徑 50 公尺範圍內。

[stamp.stamp_tour_provider.body.8]
KO: ${unlocked.name} 스탬프 획득! ${AppStrings.stampTourOfficialDiaPending}
ZH: 獲得 ${unlocked.name} 集章！${AppStrings.stampTourOfficialDiaPending}

[stamp.stamp_tour_provider.body.9]
KO: ${unlocked.name} 개인 스탬프 기록됨 (공식 DIA 없음)
ZH: 已記錄 ${unlocked.name} 個人集章 (無官方 DIA)

[app.dashboardStampTourCta]
KO: 스탬프 투어 확인하기
ZH: 查看集章巡禮

[app.stampTourLandmarkGangbyeon]
KO: 강변 공원
ZH: 江邊公園

[app.stampTourLandmarkModoil]
KO: 모도일 공원
ZH: 模都一公園

[app.stampTourLandmarkNamsan]
KO: 남산타워
ZH: 南山塔

[app.stampTourMissionStamp]
KO: 우리 동네 랜드마크 스탬프 찍기 (1/3)
ZH: 收集本地地標集章 (1/3)

[app.stampTourMissionWalk]
KO: 오늘 가볍게 1km 걷기
ZH: 今天輕鬆散步 1km

[app.stampTourMissionWalkReward]
KO: DIA 지급 대기
ZH: 等待發放 DIA

[app.stampTourStampCollected]
KO: 스탬프 완료
ZH: 集章完成

[app.stampTourTitle]
KO: 스탬프 투어 & 미션
ZH: 集章巡禮與任務

[app.stampTourVisitComplete]
KO: 방문 완료!
ZH: 造訪完成！

[stamp_tour.body]
KO: ${AppStrings.stampTourStampCollected} (개인)
ZH: ${AppStrings.stampTourStampCollected} (個人)

[stamp_tour.body.2]
KO: 개인 스탬프 · 반경 50m
ZH: 個人集章 · 半徑 50m

[stamp_tour.body.3]
KO: 공식 랜드마크 · 반경 50m
ZH: 官方地標 · 半徑 50m

[stamp_tour.body.4]
KO: 서울
ZH: 首爾

[stamp_tour.body.5]
KO: 획득 완료
ZH: 已獲得

[store.body]
KO: ${_groupDigits(value)}원
ZH: ${_groupDigits(value)} 韓元

[store.body.2]
KO: $out원
ZH: $out 韓元

[app.iapBillingSubtitle]
KO: 구글 플레이 공식 보안 결제를 적용합니다.
ZH: 採用 Google Play 官方安全支付。

[app.iapBillingTitle]
KO: 다이아 교환소
ZH: DIA 兌換所

[app.storeBuyDia]
KO: 30 DIA 구매
ZH: 購買 30 DIA

[app.storeFunctionalItems]
KO: 기능성 아이템
ZH: 功能性道具

[app.walletHistoryShortcutTooltip]
KO: 재화 히스토리
ZH: 貨幣紀錄

[subscription_management.body]
KO: 구독
ZH: 訂閱

[subscription_management.body.2]
KO: 무료 기본 러닝 안내
심박·상황에 맞춘 심층 코칭
ZH: 免費基本跑步指導
結合心率與狀態的深度指導

[app.termsAllAgree]
KO: [전체 동의] 쉐어런챌린지 이용약관
ZH: [全部同意] ShareRun 挑戰服務條款

[app.termsOptionalHealth]
KO: [선택] 건강정보(심박수) 수집 및
이용 동의
ZH: [選填] 同意收集與使用
健康資訊（心率）

[app.termsRequiredAge14]
KO: [필수] 만 14세 이상입니다
ZH: [必填] 年滿 14 歲

[app.termsRequiredLocation]
KO: [필수] 위치기반서비스 이용약관 동의
ZH: [必填] 同意基於位置服務的服務條款

[app.termsRequiredPrivacy]
KO: [필수] 개인정보 수집 및 이용 동의
ZH: [必填] 同意收集與使用個人資料

[app.termsRequiredService]
KO: [필수] 쉐어런챌린지 서비스 이용약관
ZH: [必填] ShareRun 挑戰服務條款

[app.termsSubtitle]
KO: 안전하고 공정한 쉐어런 생태계를 위해 필수
항목에 동의해 주세요.
ZH: 為了安全且公正的ShareRun生態圈，
請同意必填項目。

[app.termsTitle]
KO: 환영합니다!
시작 전 약관 동의가
필요합니다.
ZH: 歡迎！
開始前需要
同意服務條款。

[tournament.body]
KO: 내 티어 $userTier
ZH: 我的等級 $userTier

[tournament.body.10]
KO: 그 밖의 대회
ZH: 其他賽事

[tournament.body.11]
KO: 낮은 등급 대회는 참가할 수 없어요
ZH: 無法參加較低等級的賽事

[tournament.body.12]
KO: 이미 참가했어요
ZH: 已參加

[tournament.body.13]
KO: 모집이 끝났어요
ZH: 招募已結束

[tournament.body.14]
KO: 후원  ${displaySponsorName(room.sponsorName)}
ZH: 贊助商  ${displaySponsorName(room.sponsorName)}

[tournament.body.15]
KO: 목표 거리
ZH: 目標距離

[tournament.body.16]
KO: 참가비
ZH: 報名費

[tournament.body.17]
KO: 모집
ZH: 招募

[tournament.body.18]
KO: 이 대회 후원하기
ZH: 贊助此賽事

[tournament.body.19]
KO: 내 대회 ($count)
ZH: 我的賽事 ($count)

[tournament.body.2]
KO: 검증된 달리기 1km마다 100원을 기부할 예정이에요.
ZH: 預計每完成 1 公里驗證跑步，就捐出 100 韓元。

[tournament.body.3]
KO: 회사(운영자) 자금으로 기부할 예정이며 월 한도가 있어요. 기부처는 협의 중이고 정해지면 알려 드려요.
ZH: 預計以公司（營運方）資金捐出，並設有每月上限。受贈機構仍在洽談中，確定後將另行通知。

[tournament.body.4]
KO: 아직 열린 대회가 없어요
ZH: 目前尚無開放的賽事

[tournament.body.5]
KO: 새 대회가 열리면 여기에 나타나요.
ZH: 當新賽事開放時，將會顯示於此。

[tournament.body.6]
KO: 티어 대회
ZH: 階級聯賽

[tournament.body.7]
KO: 등급을 받으면 참가할 수 있어요
ZH: 獲得等級後即可參加

[tournament.body.8]
KO: 자유 대회
ZH: 自由聯賽

[tournament.body.9]
KO: 누구나 참가 · 승급 점수 절반
ZH: 任何人皆可參加 · 升級積分減半

[tournament.button]
KO: 무료 참가권으로 참가
ZH: 使用免費參賽券參加

[tournament_detail.body]
KO: 대회를 찾을 수 없습니다.
ZH: 找不到比賽。

[tournament_detail.body.10]
KO: 상태: ${_statusKo(room.status)}
ZH: 狀態: ${_statusKo(room.status)}

[tournament_detail.body.11]
KO: 목표 거리: ${room.targetDistanceKm.toStringAsFixed(1)} km
ZH: 目標距離: ${room.targetDistanceKm.toStringAsFixed(1)} km

[tournament_detail.body.12]
KO: 참가비: $entryFeeShare SHARE
ZH: 參賽費: $entryFeeShare SHARE

[tournament_detail.body.13]
KO: 참가비: $feeText
ZH: 參賽費: $feeText

[tournament_detail.body.14]
KO: 모집 인원이 차지 않아 참가비를 돌려드렸어요.
ZH: 因未達招募人數，已退還參賽費。

[tournament_detail.body.15]
KO: 참가 상태: ${participantStatus ==
ZH: 參賽狀態: ${participantStatus ==

[tournament_detail.body.16]
KO: 참가일: ${_formatDate(joinedAt!)}
ZH: 參賽日期: ${_formatDate(joinedAt!)}

[tournament_detail.body.17]
KO: 모집 중
ZH: 招募中

[tournament_detail.body.18]
KO: 진행 중
ZH: 進行中

[tournament_detail.body.19]
KO: 취소됨
ZH: 已取消

[tournament_detail.body.2]
KO: 추가 참가권으로 참가
ZH: 使用額外參賽券參加

[tournament_detail.body.20]
KO: 인원 미달로 취소됨
ZH: 因人數不足而取消

[tournament_detail.body.21]
KO: 종료
ZH: 已結束

[tournament_detail.body.3]
KO: ${room.entryFeeShare} SHARE로 참가
ZH: 以 ${room.entryFeeShare} SHARE 參加

[tournament_detail.body.4]
KO: 로그인 후 참가할 수 있습니다.
ZH: 登入後即可參加。

[tournament_detail.body.5]
KO: 현재 티어에서는 참가할 수 없습니다.
ZH: 目前階級無法參加。

[tournament_detail.body.6]
KO: 정원이 가득 찼습니다.
ZH: 人數已滿。

[tournament_detail.body.7]
KO: 모집이 종료된 대회입니다.
ZH: 報名已截止的比賽。

[tournament_detail.body.8]
KO: 스폰서 후원하기
ZH: 贊助商贊助

[tournament_detail.body.9]
KO: 후원: ${displaySponsorName(room.sponsorName)}
ZH: 贊助者: ${displaySponsorName(room.sponsorName)}

[tournament_detail.button]
KO: 이미 참가한 대회입니다.
ZH: 已參加此比賽

[tournament_detail.button.2]
KO: 대회 목록에서 보기
ZH: 在比賽列表中檢視

[tournament_detail.button.3]
KO: 러닝 시작하기
ZH: 開始跑步

[tournament_detail.title]
KO: 대회 상세
ZH: 比賽詳情

[tournament_model.body]
KO: 참가자 $participantCount/$maxParticipants명
ZH: 參賽者 $participantCount/$maxParticipants 人

[tournament_model.body.2]
KO: 참가자 $participantCount명
ZH: 參賽者 $participantCount 人

[tournament_model.body.3]
KO: 기부 풀: $donationValue VALUE
ZH: 捐款池：$donationValue VALUE

[tournament_model.body.4]
KO: 쉐어런 대회
ZH: ShareRun 賽事

[tournament_model.body.5]
KO: 쉐어런 스폰서
ZH: ShareRun 贊助商

[tournaments.prize_display.body]
KO: ${won ~/ 10000}만 원 상당 다이아
ZH: 價值 ${won ~/ 10000} 萬韓元的 DIA

[tournaments.prize_display.body.2]
KO: ${_grouped(won)}원 상당 다이아
ZH: 價值 ${_grouped(won)} 韓元的 DIA

[tournaments.prize_display.body.3]
KO: 상금을 확인하는 중이에요
ZH: 正在確認獎金

[tournaments.prize_display.body.4]
KO: 상금을 불러오지 못했어요
ZH: 無法載入獎金

[tournaments.prize_race_entry.body]
KO: 참가비 확인 중
ZH: 正在確認報名費

[tournaments.prize_race_entry.body.2]
KO: 참가비를 불러오지 못했습니다
ZH: 無法載入報名費

[tournaments.prize_race_entry.body.3]
KO: 무료 참가
ZH: 免費參加

[tournaments.prize_race_entry.body.4]
KO: 무료 참가권 $ticketCost장
ZH: 免費入場券 $ticketCost 張

[tournaments.prize_race_entry.body.5]
KO: $entryShare SHARE 또는 무료 참가권 $ticketCost장
ZH: $entryShare SHARE 或免費入場券 $ticketCost 張

[tournaments.prize_race_entry.body.6]
KO: $base · 보유 $held장
ZH: $base · 持有 $held 張

[tournaments.prize_race_entry.body.7]
KO: $freeEntryLabel로 참가
ZH: 使用 $freeEntryLabel 參加

[tournaments.prize_race_entry.body.8]
KO: $entryShare SHARE로 참가
ZH: 以 $entryShare SHARE 參加

[tournaments.prize_race_entry.body.9]
KO: 무료 참가권 $ticketCost장으로 참가
ZH: 使用免費入場券 $ticketCost 張參加

[tournaments.sponsor_display.body]
KO: 운영자
ZH: 營運者

[tournaments.tournament_join_flow.body]
KO: 로그인 후 챌린지에 참가할 수 있습니다.
ZH: 登入後即可參加挑戰。

[tournaments.tournament_join_flow.body.2]
KO: 이미 참가한 챌린지입니다.
ZH: 您已參加此挑戰。

[tournaments.tournament_join_gate.body]
KO: SHARE 잔액이 부족합니다.
ZH: SHARE 餘額不足。

[tournaments.tournament_join_outcome.body]
KO: 이미 참가한 챌린지입니다. 참가비는 다시 차감되지 않습니다.
ZH: 您已參加此挑戰。不會再次扣除報名費。

[tournaments.tournament_join_outcome.body.2]
KO: 참가가 거절되었습니다. 참가비는 차감되지 않았습니다.
ZH: 參加已被拒絕。未扣除報名費。

[tournaments.tournament_join_outcome.body.3]
KO: 참가·결제가 완료되지 않았습니다. 서버 연결 또는 인증에 실패했습니다.
ZH: 未能完成參加與付款。伺服器連線或驗證失敗。

[tournaments.tournament_join_outcome.body.4]
KO: 참가 완료.
ZH: 參加完成。

[tournaments.tournament_join_outcome.body.5]
KO: 참가 완료. 참가비 $fee SHARE가 잠겼습니다.
ZH: 參加完成。已鎖定報名費 $fee SHARE。

[tournaments.tournament_join_outcome.body.6]
KO: 참가 완료(디버그). 참가비 $fee SHARE가 차감되었습니다.
ZH: 參加完成(除錯)。已扣除報名費 $fee SHARE。

[user_model.body]
KO: 미연동
ZH: 未連結

[user_model.body.2]
KO: 여
ZH: 女

[user_model.body.3]
KO: 여성
ZH: 女性

[voice_coaching.voice_coaching_cues.body]
KO: 보이스 코칭을 켤게요.
ZH: 即將開啟語音指導。

[voice_coaching.voice_coaching_cues.body.10]
KO: 심박이 좋아요. 이 페이스 유지해요.
ZH: 心率良好，保持這個配速。

[voice_coaching.voice_coaching_cues.body.11]
KO: 심박이 내려왔어요. 페이스 유지해요.
ZH: 心率已降下來，保持這個配速。

[voice_coaching.voice_coaching_cues.body.12]
KO: 천 보 달성! 좋아요.
ZH: 達成1,000步！太棒了。

[voice_coaching.voice_coaching_cues.body.13]
KO: 삼천 보예요. 페이스 잘 유지하고 있어요.
ZH: 3,000步了，配速保持得很好。

[voice_coaching.voice_coaching_cues.body.14]
KO: 오천 보! 잘하고 있어요.
ZH: 5,000步！做得很好。

[voice_coaching.voice_coaching_cues.body.15]
KO: 팔천 보. 거의 다 왔어요.
ZH: 8,000步，就快到了。

[voice_coaching.voice_coaching_cues.body.16]
KO: 만 보 달성! 오늘 정말 잘했어요.
ZH: 達成10,000步！今天真的很棒。

[voice_coaching.voice_coaching_cues.body.17]
KO: $steps보 달성! 좋아요.
ZH: 達成$steps步！太棒了。

[voice_coaching.voice_coaching_cues.body.18]
KO: 1킬로미터. 호흡 유지하고 가요.
ZH: 1公里，保持呼吸繼續前進。

[voice_coaching.voice_coaching_cues.body.19]
KO: $km킬로미터. 이 페이스 유지해요.
ZH: $km公里，保持這個配速。

[voice_coaching.voice_coaching_cues.body.2]
KO: 워킹 챌린지 시작이에요. 천천히 걸어볼까요?
ZH: 健走挑戰開始了。一起慢慢散步吧？

[voice_coaching.voice_coaching_cues.body.20]
KO: 1킬로미터. 페이스 좋아요.
ZH: 1公里，配速很好。

[voice_coaching.voice_coaching_cues.body.21]
KO: $km킬로미터 통과. 잘하고 있어요.
ZH: 通過$km公里，表現得很棒。

[voice_coaching.voice_coaching_cues.body.3]
KO: SHARE를 수확했어요. 수고했어요.
ZH: 已收穫 SHARE。辛苦了！

[voice_coaching.voice_coaching_cues.body.4]
KO: 오늘의 목표 거리를 채웠어요. 대단해요!
ZH: 已達成今天的目標距離。太棒了！

[voice_coaching.voice_coaching_cues.body.5]
KO: 러닝을 시작해요. 호흡을 맞춰볼까요?
ZH: 開始跑步。調整一下呼吸節奏吧？

[voice_coaching.voice_coaching_cues.body.6]
KO: 러닝 종료. 오늘도 잘 달렸어요.
ZH: 跑步結束。今天也跑得很棒！

[voice_coaching.voice_coaching_cues.body.7]
KO: 200미터 남았어요.
ZH: 還剩 200 公尺。

[voice_coaching.voice_coaching_cues.body.8]
KO: 좋아요. 호흡 유지해요.
ZH: 很好，保持呼吸節奏。
