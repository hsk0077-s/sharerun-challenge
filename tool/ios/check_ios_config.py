#!/usr/bin/env python3
"""Mac에서 iOS 프로젝트를 만든 뒤(또는 만들기 전) 꼭 남아 있어야 할 iOS 설정을 확인한다.

  python3 tool/ios/check_ios_config.py            # 현재 ios/ 를 검사
  python3 tool/ios/check_ios_config.py --json     # 결과를 JSON으로
  IOS_DIR=/다른/경로/ios python3 tool/ios/check_ios_config.py   # 다른 ios 폴더 검사

값(키, 비밀)은 출력하지 않는다. 항목 이름과 통과/실패만 보여 준다. 실패가 하나라도 있으면 종료 코드 1.
`Runner.xcodeproj`가 아직 없으면 그 항목은 "건너뜀"(실패 아님)으로 표시한다.
"""
from __future__ import annotations

import json
import os
import plistlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IOS = Path(os.environ.get("IOS_DIR", ROOT / "ios"))
BUNDLE_ID = "com.sharerun.shareRunChallenge"

REQUIRED_USAGE_KEYS = [
    "NSBluetoothAlwaysUsageDescription",
    "NSHealthShareUsageDescription",
    "NSLocationAlwaysAndWhenInUseUsageDescription",
    "NSLocationWhenInUseUsageDescription",
    "NSMotionUsageDescription",
    "NSMicrophoneUsageDescription",
    "NSSpeechRecognitionUsageDescription",
    "NSCameraUsageDescription",
    "NSPhotoLibraryUsageDescription",
]
REQUIRED_BACKGROUND = {"location", "bluetooth-central", "fetch"}
REQUIRED_BG_TASK = "com.pravera.flutter_foreground_task.refresh"
KAKAO_SCHEME = re.compile(r"^kakao[0-9a-f]{20,}$")


def load_plist(path: Path):
    with path.open("rb") as handle:
        return plistlib.load(handle)


def main() -> int:
    results: list[tuple[str, str, str]] = []  # (status, name, detail)

    def check(name: str, ok: bool, detail: str = "") -> None:
        results.append(("통과" if ok else "실패", name, detail))

    def skip(name: str, detail: str) -> None:
        results.append(("건너뜀", name, detail))

    info_path = IOS / "Runner" / "Info.plist"
    if not info_path.exists():
        check("Info.plist 존재", False, str(info_path))
    else:
        info = load_plist(info_path)
        check("Info.plist 존재", True)
        for key in REQUIRED_USAGE_KEYS:
            check(f"권한 문구 {key}", bool(str(info.get(key, "")).strip()))
        modes = set(info.get("UIBackgroundModes", []))
        for mode in sorted(REQUIRED_BACKGROUND):
            check(f"백그라운드 모드 {mode}", mode in modes)
        check(
            "BGTaskSchedulerPermittedIdentifiers(foreground_task)",
            REQUIRED_BG_TASK in info.get("BGTaskSchedulerPermittedIdentifiers", []),
        )
        schemes = [
            scheme
            for entry in info.get("CFBundleURLTypes", [])
            for scheme in entry.get("CFBundleURLSchemes", [])
        ]
        check("카카오 URL 스킴(kakao…)", any(KAKAO_SCHEME.match(s) for s in schemes))
        queries = set(info.get("LSApplicationQueriesSchemes", []))
        for scheme in ("kakaotalk", "kakaolink", "instagram-stories"):
            check(f"LSApplicationQueriesSchemes {scheme}", scheme in queries)
        check("CFBundleDisplayName 쉐어런", info.get("CFBundleDisplayName") == "쉐어런")
        check(
            "PRODUCT_BUNDLE_IDENTIFIER 변수 유지",
            info.get("CFBundleIdentifier") == "$(PRODUCT_BUNDLE_IDENTIFIER)",
        )
        # 구글 로그인(GoogleService-Info.plist 뒤에 넣는 값): 있으면 통과, 없으면 '건너뜀'
        if "GIDClientID" in info:
            check("구글 로그인 GIDClientID", True)
        else:
            skip("구글 로그인 GIDClientID", "Firebase iOS 앱 등록 뒤 추가(아직 없음)")

    ent_path = IOS / "Runner" / "Runner.entitlements"
    if not ent_path.exists():
        check("Runner.entitlements 존재", False)
    else:
        ent = load_plist(ent_path)
        check("HealthKit entitlement", ent.get("com.apple.developer.healthkit") is True)
        for key, label in (
            ("com.apple.developer.applesignin", "Sign in with Apple entitlement"),
            ("aps-environment", "푸시(aps-environment) entitlement"),
        ):
            if key in ent:
                check(label, True)
            else:
                skip(label, "Capability 추가 때 Xcode가 넣는다(아직 없음)")

    for rel in ("AppDelegate.swift", "BleHeartRatePlugin.swift", "WatchBridgePlugin.swift"):
        check(f"Runner/{rel} 존재", (IOS / "Runner" / rel).exists())

    pbx = IOS / "Runner.xcodeproj" / "project.pbxproj"
    if not pbx.exists():
        skip("Runner.xcodeproj 번들 ID", "프로젝트가 아직 없다(Mac에서 생성 예정)")
    else:
        text = pbx.read_text(encoding="utf-8", errors="ignore")
        ids = set(re.findall(r"PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);", text))
        runner_ids = {i.strip() for i in ids if "RunnerTests" not in i}
        check(f"번들 ID {BUNDLE_ID}", BUNDLE_ID in runner_ids, f"발견: {sorted(runner_ids)}")
        check("IPHONEOS_DEPLOYMENT_TARGET >= 15.0", _deployment_ok(text))
        for rel in ("BleHeartRatePlugin.swift", "WatchBridgePlugin.swift"):
            check(f"타깃에 {rel} 포함", rel in text)

    width = max(len(name) for _, name, _ in results)
    for status, name, detail in results:
        print(f"[{status}] {name.ljust(width)}  {detail}".rstrip())
    failed = [r for r in results if r[0] == "실패"]
    print(f"\n통과 {sum(r[0] == '통과' for r in results)}, 실패 {len(failed)}, 건너뜀 {sum(r[0] == '건너뜀' for r in results)}")
    if "--json" in sys.argv:
        print(json.dumps([{"status": s, "name": n, "detail": d} for s, n, d in results], ensure_ascii=False))
    return 1 if failed else 0


def _deployment_ok(pbx_text: str) -> bool:
    targets = [float(v) for v in re.findall(r"IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);", pbx_text)]
    return bool(targets) and min(targets) >= 15.0


if __name__ == "__main__":
    sys.exit(main())
