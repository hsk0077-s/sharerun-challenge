# 아직 번역에 연결되지 않은 하드코딩 한국어 (대략)

`lib/` 안의 한국어 글자열 중 `RemainingSurface.tr`/`trNow`나 `ShareRunLocalizations`로 감싸지 않은 것을 찾은 목록입니다.
주석, `lib/l10n/`(번역 표), `legal_constants.dart`(약관)는 뺐습니다. 근사치이므로 한 줄씩 확인이 필요합니다.
화면에 안 보이는 것(닉네임 금지어, 서버 영어 메시지를 한국어로 바꾸는 표, 로그)도 섞여 있습니다.

파일 134개, 글자열 약 1061개

| 개수 | 파일 | 예 |
|---:|---|---|
| 126 | `lib/features/mini_bot/mini_bot_intent.dart` | 63: 후원하기 / 66: 구매하기 |
| 74 | `lib/features/onboarding/src_onboarding_controller.dart` | 56: 거북이 / 57: 비글 |
| 61 | `lib/features/accessories/accessory_catalog.dart` | 12: 등 / 13: 하의 |
| 53 | `lib/core/strings/app_strings.dart` | 8: 쉐어런 / 9: 쉐어런 |
| 50 | `lib/data/models/wallet_transaction_model.dart` | 28: 휴식일 지정권 / 31: 휴식일 지정 |
| 47 | `lib/screens/wearable_brand_guide_sheet.dart` | 46: 샤오미 미밴드 / 레드미 워치 / 47: Mi Fitness (구형은 Zepp Life) |
| 31 | `lib/features/crew/crew_emblem.dart` | 306: 달리기 · 운동 / 324: 자연 |
| 30 | `lib/data/models/shop_item_model.dart` | 37: 기록 심폐소생권 / 38: 끊긴 연속 출석을 72시간 안에 되돌립니다. 한 달에 2번까지. |
| 27 | `lib/features/mini_bot/mini_bot_sheet.dart` | 30: 궁금한 게 있으면 저를 눌러 물어보세요 / 31: 오늘 목표나 SHARE가 궁금하면 물어보세요 |
| 27 | `lib/features/run_result/run_finish_share_card.dart` | 51: 다크 / 52: 블루 |
| 25 | `lib/features/iap/services/iap_purchase_controller.dart` | 95: Google Play 결제 서비스를 사용할 수 없습니다. 잠시 후 다시 시도해 주세요. / 114: 상품(${plan.productId})을 찾지 못했습니다. Play Console / App Store Co |
| 21 | `lib/features/voice_coaching/voice_coaching_cues.dart` | 38: 보이스 코칭을 켤게요. / 45: 워킹 챌린지 시작이에요. 천천히 걸어볼까요? |
| 20 | `lib/features/run_tracking/run_recording_checklist.dart` | 181: 배터리 설정 화면을 열지 못했습니다. / 216: 달리기 기록 설정 |
| 20 | `lib/screens/running_crew_screen.dart` | 139: DIA가 부족합니다. 상점에서 구매해 주세요. / 401: 취소 |
| 19 | `lib/screens/login_connections_screen.dart` | 86: 취소 / 129: 취소 |
| 16 | `lib/screens/snail_to_cheetah_book_page.dart` | 37: 뒤로 / 320: 거북이 |
| 15 | `lib/features/jena_validation/verification_reason.dart` | 8: 거리가 이번 대회의 최소 거리보다 짧아요. 대회 거리만큼, 적어도 1km는 달려야 해요.  / 9: 기록은 남고 보상은 지급되지 않아요. |
| 15 | `lib/features/shop/streak_item_message.dart` | 29: 부스트 런은 하루에 1번까지 사용할 수 있습니다. / 30: 만보기 부화기는 한 번에 하나만 동작합니다. |
| 14 | `lib/data/repositories/auth_repository.dart` | 73: 구글 로그인 설정 오류: ${e.description ?? e.code.name} / 75: Firebase 로그인 실패: ${e.message} |
| 14 | `lib/screens/solo_pedometer_screen.dart` | 163: [PERSISTENCE] 로컬/원격 데이터 복원 실패: $e / 198: [PERSISTENCE] 상한 조회 실패: $e |
| 10 | `lib/features/profile/village_scene.dart` | 34: 기본 마을 / 46: 봄 공원 |
| 10 | `lib/features/jena_validation/verification_guidance.dart` | 49: 이번 대회의 검증 최소 거리는 $distance예요. 대회 거리가 더 짧아도 1km는 넘어야 해요. / 50: 분당 걸음 수는 120~210이어야 해요. |
| 9 | `lib/features/run_result/run_finish_share_flow.dart` | 14: 하나만 올리기 / 15: 여러 개 순서대로 올리기 |
| 8 | `lib/features/run_tracking/music_controls.dart` | 97: 이전 곡 / 99: 음악을 조절하지 못했어요. |
| 8 | `lib/features/run_tracking/run_recording_policy.dart` | 2: 쉐어런 · 달리기 기록 중 / 4: 이전 달리기가 중단되었습니다 |
| 8 | `lib/features/profile/invite_copy.dart` | 50: 내 초대 코드 / 51: 복사 |
| 8 | `lib/features/shop/cosmetics_catalog.dart` | 55: 민트 러닝화 / 65: 블루 러닝화 |
| 8 | `lib/features/my_page/widgets/pace_calculator_card.dart` | 41: 목표 페이스 계산기 / 51: 목표 거리 (km) |
| 8 | `lib/core/notifications/reminder_schedule.dart` | 62: 워킹챌린지 참여 독려 / 63: 워킹챌린지 아침·점심·저녁 참여 독려 |
| 8 | `lib/screens/crew_room_screen.dart` | 19: 크루장 / 20: 부크루장 |
| 8 | `lib/screens/login_screen.dart` | 132: 구글 / 142: 애플 |
| 8 | `lib/screens/watch_app_preview_screen.dart` | 215: 손목에서 바로 뛸 수 있는 쉐어런 워치 앱을 준비하고 있어요.  / 216: 워치 앱이 설치된 시계에서 아래 연결 코드를 입력하면 연결돼요.  |
| 7 | `lib/features/profile/avatar_choice.dart` | 95: 여성 / 100: 달팽이 |
| 7 | `lib/features/profile/widgets/retention_widgets.dart` | 354: 월 / 354: 화 |
| 7 | `lib/features/report/report_dialog.dart` | 5: 욕설·불쾌한 이름 / 6: 선정적인 이름 |
| 7 | `lib/features/launch/intro_screen.dart` | 30: 걸으면 SHARE가 쌓여요 / 31: 한 걸음이 나눔이 된다 |
| 7 | `lib/screens/my_page_screen.dart` | 199: 확인 / 246: 마이페이지 |
| 7 | `lib/screens/device_connection_screen.dart` | 84: 닫기 / 294: 로그인이 필요합니다. |
| 6 | `lib/features/profile/widgets/my_page_invite_code_card.dart` | 48: 내 초대 코드 / 49: 복사 |
| 6 | `lib/features/tournaments/utils/tournament_join_gate.dart` | 23: 로그인 후 챌린지에 참가할 수 있습니다. / 26: 이미 참가한 챌린지입니다. |
| 6 | `lib/data/models/payment_intent_status_model.dart` | 24: 결제가 확인되어 잔액에 반영되었습니다. / 25: PG 결제를 완료하면 자동으로 확인됩니다. |
| 6 | `lib/screens/crew_manager_screen.dart` | 54: 취소 / 116: 취소 |
| 5 | `lib/features/run_result/run_finish_image_share.dart` | 16: Instagram 스토리 / 18: 더보기 |
| 5 | `lib/features/iap/payment_auth.dart` | 20: 본인 확인이 취소됐어요. 결제는 진행되지 않았어요. / 22: 확인을 여러 번 틀려 잠시 막혔어요. 잠시 뒤 다시 하거나 화면 잠금(PIN, 패턴)으로 확인해 주세요. 결 |
| 5 | `lib/features/iap/widgets/coach_plus_upsell_sheet.dart` | 75: 무료 / 75: 기본 러닝 안내 |
| 5 | `lib/features/iap/widgets/dia_notice.dart` | 21: 1 DIA는 100원이에요. / 22: 돈으로 산 DIA(유료)와 무료로 받은 DIA(보너스)가 있어요. 쓸 때는 보너스 DIA를 먼저 써요. |
| 5 | `lib/features/reward/view/winner_honor_popup.dart` | 144: 챌린지 우승! / 152: 당신의 땀방울이 세상을 바꿉니다. |
| 5 | `lib/features/reward/view/winner_reward_dialog.dart` | 23: 우승 임팩트 / 28: 축하합니다! 검증된 러닝으로 우승 상금을 획득했습니다. |
| 5 | `lib/features/map_crew/widgets/crew_member_ranking_board.dart` | 19: 크루원 랭킹 데이터 없음 / 20: 출석률·평균 페이스가 여기에 표시됩니다. |
| 5 | `lib/data/models/tournament_model.dart` | 76: 참가자 $participantCount/$maxParticipants명 / 78: 참가자 $participantCount명 |
| 4 | `lib/features/accessories/try_on_sheet.dart` | 56: ${widget.title} 입혀 보기 / 61: 구경용이에요. 저장되거나 구매되지 않아요. |
| 4 | `lib/features/accessories/accessory_names.dart` | 74: {name}을(를) {price}로 살까요? / 87: {name}을(를) 샀어요. |
| 4 | `lib/features/appeal/appeal_hold.dart` | 11: $km km 달리기 / 19: ${at.month}월 ${at.day}일 $hh:$mm |
| 4 | `lib/features/run_result/run_finish_share_targets.dart` | 5: Instagram 스토리 / 6: Instagram 피드 |
| 4 | `lib/features/iap/models/coach_plus_product.dart` | 45: 월간 / 46: 6,900원 |
| 4 | `lib/features/jena_validation/services/jena_pending_gate.dart` | 27: 케이던스(발구름) 데이터가 없거나 0입니다. 기록이 보류되었습니다. / 41: 심박수 추이가 페이스 증가에 반응하지 않아 차량·자전거·킥보드 탑승이 의심됩니다. |
| 4 | `lib/features/shop/widgets/accessory_shop_grid.dart` | 167: 보유 / 170: 티어 보상 |
| 4 | `lib/features/pedometer/daily_metrics_account.dart` | 176: [CLOUD RECOVERY] daily_metrics 읽기 실패: $e / 189: [CLOUD RECOVERY] daily_metrics 캐시 실패: $e |
| 4 | `lib/features/my_page/widgets/shoe_mileage_tracker.dart` | 37: 러닝화 마일리지 트래커 / 58: 장착 중 · $skinName |
| 4 | `lib/screens/charge_screen.dart` | 158: 신용/체크카드 / 159: 토스페이 |
