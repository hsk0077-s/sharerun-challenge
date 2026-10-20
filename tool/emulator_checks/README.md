# 에뮬레이터 검증

진짜 Firestore 에뮬레이터로 보안 규칙과 서버 거래(트랜잭션)를 돌려 보는 스크립트입니다. 메모리 가짜 DB 테스트가 못 잡는 것을 확인하려는 용도입니다.

준비 (한 번): 이 폴더에서 `npm i firebase-tools@13 @firebase/rules-unit-testing@3 firebase@10`

실행:
```
npx firebase emulators:exec --config fb.json --project demo-sr --only firestore "node rules.test.mjs"
FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 npx firebase emulators:exec --config fb.json --project demo-sr --only firestore "python3 e2e.py"
```
- `rules.test.mjs`: 승급 원장·승급 점수·입장권 재고를 사용자가 못 쓰는지.
- `e2e.py`: 도전 입장권 구매 → 티어 대회 입장 → 완주 → 정산 → 승급 점수 한 번만 지급.
