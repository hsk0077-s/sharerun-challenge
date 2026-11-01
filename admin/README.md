# 쉐어런 관리자 (admin)

React 19 + Vite + Tailwind 관리자 웹. Firebase 프로젝트 `share-run-challenge`, 서버 API는 `backend/jena_ai`(Cloud Run)의 `/admin/*`.

## 실행·배포

```bash
cd admin
cp .env.example .env     # 개발 서버는 .env 가 없으면 시작하지 않습니다 (실서비스 프로젝트에 실수로 붙지 않게)
npm install
npm run dev              # 로컬
npm run build            # dist/ 생성
firebase deploy --only hosting:admin
```

## 누가 들어올 수 있나

- Firebase Auth 로그인 + `admin` 클레임 또는 `admins/{uid}` 문서가 있는 계정만.
- 서버 `/admin/*`는 매번 같은 기준으로 다시 확인하고, 열람·변경은 `adminAuditLogs`에 남깁니다.

## 2단계 인증(2FA)

관리자 계정은 Firebase Auth의 다단계 인증으로 보호하는 것을 권장합니다. 코드가 아니라 콘솔 설정입니다.

1. Firebase 콘솔 → Authentication → Sign-in method → **SMS 다단계 인증** 사용 설정 (Identity Platform으로 업그레이드 필요).
2. 각 관리자 계정이 등록(휴대폰 번호)을 마치면 이후 로그인에 코드가 필요합니다.
3. 등록하지 않은 관리자는 계속 비밀번호만으로 들어올 수 있으므로, 전원이 등록했는지 확인하세요.

이 앱의 로그인 화면은 2단계 코드 입력을 아직 지원하지 않습니다. 콘솔에서 2FA를 강제하기 전에 로그인 화면 대응이 먼저 필요합니다.

## 화면

통합 대시보드 · 유저/크루 · Jena 어뷰징 심사 · 재무/환불 · 추천인 · 스폰서 현황(조회) · 설정 값(조회) · 일별 걸음 · 지갑 이상 · 런 검증 · 지갑 원장 · 신고 · 감사 로그.

## 알아둘 점

- 유저 목록은 최대 1,000명을 실시간으로 듣습니다. 가입자가 더 많으면 화면에 그렇게 표시되고, 목록에 없는 계정은 UID·이메일로 서버에서 찾습니다.
- 설정 값은 읽기 전용입니다. 바꾸는 일은 서버 배포·Firestore 콘솔에서 합니다.
- 린트: `react-hooks/set-state-in-effect` 오류가 기존 파일 몇 곳에 남아 있습니다 (새 코드는 지키도록 작성).
