# 운영자 변경 (하상기 → 이어온웍스 Eareon Works)

**양도 완료 전에는 머지하지 않습니다.** 이 브랜치(`chore/operator-eareonworks`)는 약관·개인정보처리방침·스토어 설명·앱의 운영자와 연락 메일을 바꿔 두는 준비본입니다.

## 바뀐 것

| 항목 | 이전 | 이후 |
|---|---|---|
| 운영자 | 하상기 | 이어온웍스(Eareon Works). 외국어 페이지에는 `Eareon Works` |
| 연락·지원 메일 | `src791004@gmail.com` | `eareonworks@gmail.com` |

바뀐 곳:
- `site/terms.html`, `site/privacy.html`, `site/account-deletion.html`(한국어 기준본)
- `site/*.{de,en,es,fr,id,ja,pt,th,vi,zh}.html` 30개(생성물)와 그 원본 `tool/legal/src/*.json`, `tool/legal/tr/*.json`
- `tool/legal/build.py`: 번역 검사의 메일 주소와, 번역에 한글이 들어가면 막는 검사(자리표시와 한국어 본문에도 있는 이름은 허용)
- `store_listings/*/store-listing.md` 11개의 "고객 문의" 메일
- `lib/features/support/contact_support.dart`의 `supportEmail`

바꾸지 않은 곳: `docs/brag-card-v1.md`, `docs/l10n/review/brag-card-v1-review.md`의 "하상기 님"은 운영자 표기가 아니라 내부 문서에서 대표님을 부르는 말이라 그대로 뒀습니다.

## 머지 직전에 채울 자리표시

대표자 성명, 사업자등록번호, 통신판매업 신고번호, 주소는 이 저장소에 넣지 않았습니다. 아래 `{{...}}`가 11개 언어 페이지 모두에 들어 있습니다.

| 자리표시 | 들어간 곳 | 채울 값 |
|---|---|---|
| `{{시행일}}` | 약관·방침 맨 위 "시행일", 방침 9항 "…부터 적용", 이전 방침 줄, 운영자 변경 줄 | 새 약관·방침 시행일 (예: 2026-12-10) |
| `{{최종수정일}}` | 약관·방침 맨 위 "최종 수정일" | 마지막으로 고친 날 |
| `{{대표자명}}` | 약관 13항 문의 | 대표자 성명 |
| `{{사업자등록번호}}` | 약관 13항 문의 | 사업자등록번호 |
| `{{통신판매업신고번호}}` | 약관 13항 문의 | 통신판매업 신고번호(아직 없거나 해당 없으면 그 줄을 지움) |
| `{{사업장주소}}` | 약관 13항 문의 | 사업장 주소 |
| `{{개인정보보호책임자}}` | 방침 8항 | 개인정보 보호 책임자 성명 또는 직책 |
| `{{이전방침주소}}` | 방침 9항 "이전 방침" 줄 | 하상기 운영 시기(2026-10-25 시행) 방침을 올려 둔 주소 |

한 번에 채우기:

```
python tool/legal/fill_placeholders.py --list                # 남은 자리표시 보기
python tool/legal/fill_placeholders.py 시행일=2026-12-10 최종수정일=2026-12-10 \
  대표자명=... 사업자등록번호=... 통신판매업신고번호=... 사업장주소=... \
  개인정보보호책임자=... 이전방침주소=privacy-20261025.html
python tool/legal/build.py --check                           # 번역 검사
python tool/legal/build.py --check-filled                    # 자리표시가 남았으면 실패(머지 전 필수)
```

`fill_placeholders.py`는 `site/`와 `tool/legal/src`, `tool/legal/tr`를 함께 고칩니다. 날짜는 모든 언어 페이지에 같은 모양(2026-12-10)으로 들어갑니다.

## 머지 전에 확인할 것

1. 양도가 끝났는지(Play 앱 이전, Firebase·GCP 소유자). 끝나기 전에 머지하지 않습니다.
2. 위 자리표시를 모두 채우고 `python tool/legal/build.py --check-filled`가 통과하는지.
3. **이전 방침 보관**: 방침 9항은 이전 방침을 언제든 볼 수 있게 연결하겠다고 약속합니다. 하상기 운영 시기 방침(`privacy.html` 2026-10-25 시행본)을 새 파일로 복사해 올리고 `{{이전방침주소}}`를 그 주소로 채우세요. 자리표시를 채우기 전에 이 PR 이전의 `site/privacy.html`을 복사해 두면 됩니다.
4. **개인정보 처리자가 바뀌는 통지**: 운영자가 바뀌면 이용자에게 알려야 하는지(영업 양도에 따른 개인정보 이전 통지)를 법무에 확인하세요. 이 PR은 방침 9항에 "운영자 변경" 줄만 넣었고, 통지 여부와 방법은 판단하지 않았습니다(미확인).
5. 방침 9항은 변경을 시행일 7일 전에 앱 안 공지로 알린다고 약속합니다. 시행일을 정할 때 이 기간을 지키세요.
6. 머지 뒤: `site/` 재배포(`firebase deploy --only hosting:web`), 서버 코드는 이 PR에서 바뀐 것이 없습니다. 앱 출시 때 `supportEmail`이 새 메일로 나가는지 확인하세요.
7. Play Console 스토어 등록정보의 개발자 연락처(메일, 웹사이트), 개인정보처리방침 URL은 콘솔에서 따로 바꿉니다(이 저장소 밖).

## 같이 알아 둘 것

- `site/privacy.*.html`은 `tool/legal/build.py`로 만든 파일입니다. 사이트 문구를 고칠 때는 한국어 `site/privacy.html`을 고친 뒤 `tool/legal/extract.py`로 원본을 다시 만들고 번역을 채워야 합니다. HTML만 직접 고치면 다음 빌드에서 사라집니다(앞선 PR `fix/legal-sources-sync`가 이 문제를 고쳤습니다).
