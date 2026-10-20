"""`flutter test --reporter json` 결과에서 실패한 테스트의 이름과 이유만 출력한다."""

import json
import sys

names: dict[int, str] = {}
messages: dict[int, list[str]] = {}
failed: list[int] = []

with open(sys.argv[1], encoding="utf-8") as handle:
    for line in handle:
        try:
            event = json.loads(line)
        except ValueError:
            continue
        kind = event.get("type")
        if kind == "testStart":
            test = event["test"]
            names[test["id"]] = test["name"]
        elif kind == "error":
            messages.setdefault(event["testID"], []).append(
                f"{event.get('error', '')}\n{event.get('stackTrace', '')}"
            )
        elif kind == "testDone" and event.get("result") in {"error", "failure"}:
            if not event.get("hidden") and not event.get("skipped"):
                failed.append(event["testID"])

print(f"실패한 테스트 {len(failed)}개")
for test_id in failed:
    print("=" * 100)
    print(names.get(test_id, str(test_id)))
    for message in messages.get(test_id, []):
        print(message[:3000])
