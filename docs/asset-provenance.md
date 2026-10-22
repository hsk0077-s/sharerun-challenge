# 자료 출처 기록 (asset-provenance)

정리: 2026-10-22. 초안은 Grok(커서프로 봇), 저장소 대조와 보완은 Claude.
근거 캡처: `docs/terms-captures/` (2026-10-22 촬영, 주소창 포함). 이 문서는 법률 자문이 아니다.

## 1. 사진 (Pexels, 소유자가 사진 페이지에서 직접 확인, 2026-10-22)
자세한 기록은 `docs/splash-photo-source.md`.

| 앱 파일 | Pexels 번호 | 작가 | 라이선스 |
|---|---|---|---|
| `splash_morning_run.jpg` (홈) | 18447597 | Dean Ha | 무료 |
| `challenge_track.jpg` (챌린지 탭) | 8454901 | Mikhail Nilov | 무료 |
| `crew_crowd.jpg` (크루 탭) | 34562485 | sevim karakoç | 무료 |

## 2. AI 생성 그림 (Grok Bot 이미지 생성 기능, 생성 기간 2026-10-11~10-22)
대상: 마을 배경 8장, 아바타 남/여 v2, 티어 캐릭터(`tier_*`), 액세서리, 크루 엠블럼·글리프, 달팽이봇 얼굴(소유자 원본 달팽이 그림의 표정만 수정)

| 근거 | 날짜 | 내용 | 캡처 |
|---|---|---|---|
| Grok Bot 약관 cursor.com/terms/grok-bot | 2026-10-12 | 1.1 사용 범위 | 01 |
| SpaceXAI 약관 x.ai/legal/terms-of-service | 2026-10-12 | 4. 사용자 콘텐츠 소유권은 사용자, 출처 표기 의무, AI 생성 표시, 유사 결과물 | 02 |
| SpaceXAI FAQ x.ai/legal/faq | 2025-05-12 | "You own the Inputs and Outputs", 상업 사용 문구, 출처 표기 요청 | 03 |
| Cursor 약관 cursor.com/terms-of-service | 2026-09-03 | 1.4, 5.3 결과물 권리 | 04 |
| 이용 정책 x.ai/legal/acceptable-use-policy | 2026-08-14 | "reselling any Input or Output" 금지, 워터마크 제거 금지 | 05 |
| 브랜드 가이드 x.ai/legal/brand-guidelines | 2025-02-14 | 출처 표기 문구 "Written with Grok" 또는 "Created with Grok" | 06 |

### 지켜야 할 것
1. **출처 표기**: 브랜드 가이드는 Grok으로 만든 그림을 게시·배포하는 곳마다 "Created with Grok" 같은 문구를 읽기 쉽고 눈에 띄게 표시하라고 한다. 앱은 설정 > 약관 및 계정 지원의 "AI 생성 이미지 안내"에 `AI로 생성되었습니다. Created with Grok`를 표시한다. **스토어 설명 끝에도 한 줄 넣는다(미반영, `docs/play-store-listing.md` 작업 때 함께).**
2. **AI 생성 표시**: 위 문구가 "AI로 생성"을 함께 밝힌다.
3. **판매 아이템**: 이용 정책의 재판매 금지 조항이 인앱 아이템 판매에 해당하는지는 **미확인**. 2026-10-22 소유자가 support@x.ai에 서면 문의를 보냈고 답장을 기다리는 중이다. 답이 오기 전까지 유료 스킨·엠블럼은 "확인 대기"로 둔다.
4. 닮음 책임은 사용자에게 있다. 출시 전에 유명 캐릭터나 로고와 닮은 그림이 없는지 점검한다.

## 3. 출처 미확인 (교체 후보)
- 날개 5장 `assets/images/wings/`: 10/03~04 Cursor Agent 커밋 `48bc63d`. 제작 도구 기록 없음.
- `chibi_snail_*`: 9/9 첫 커밋, 9/12 `d015788`(기존 달팽이에서 파생). 제작 도구 기록 없음. 소유자 원본이면 소유자가 확인.
- 이전 남자 아바타: v2로 교체 완료(PR #278).

## 4. 음성
- `assets/voice/*.mp3` 100개: Google Cloud 음성 합성(Chirp 3 HD, 목소리 Leda). 소유자가 소유자의 Google Cloud 프로젝트(`share-run-challenge`)에서 `tool/build_coach_voice.dart`를 실행해 만들었고, 2026-10-12 PR #243으로 저장소에 넣었다.
- Google Cloud 약관(2026-10-12) 5.1 지식재산권 조항과 Customer Data 정의 캡처(07). 합성 음성이 Customer Data에 해당한다는 것은 해석이며 명시 조항은 못 찾았다.

## 5. 남은 확인
- 생성 기간 요금제와 동의한 약관(Cursor 또는 SpaceXAI, 소비자 또는 기업용): Grok Bot 앱 결제 화면 캡처
- support@x.ai 답장 보관(답이 오면 이 문서에 추가)
- 스토어 설명에 크레딧 한 줄 추가
- 날개 5장과 달팽이 원본의 제작 도구 확인
