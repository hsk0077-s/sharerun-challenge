#!/usr/bin/env python3
"""iOS 소스에서 Apple '필수 사유 API'(required reason API)를 쓰는 곳을 찾는다.

  flutter pub get                                  # .flutter-plugins-dependencies 를 만든다
  python3 tool/ios/scan_required_reason_apis.py
  python3 tool/ios/scan_required_reason_apis.py --lines   # 줄 단위 근거까지

무엇을 하나
- 앱 자체(`ios/Runner`, 워치 `ios/ShareRunWatch Watch App`)와 iOS를 지원하는 플러그인 소스에서
  Apple이 정한 다섯 범주(UserDefaults, 파일 시간 정보, 시스템 부팅 시간, 디스크 여유 공간, 활성 키보드)에
  해당하는 API 이름이 나오는지 글자 그대로 찾는다.
- 플러그인 폴더에 `PrivacyInfo.xcprivacy`가 있는지 같이 보여 준다.

무엇을 하지 않나
- 사유 코드를 정하지 않는다. 사유 코드는 Apple 공식 표를 보고 사람이 정한다.
- 이 스크립트는 글자 검색이라 실제 호출이 아닌 주석·문자열도 잡을 수 있고, CocoaPods로 내려받는
  바이너리 SDK(Firebase 등) 안쪽은 볼 수 없다. 배포 직전 Mac에서 Xcode의 Archive > Generate Privacy Report로
  최종 확인한다.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

CATEGORIES = {
    "UserDefaults": r"\bUserDefaults\b|\bNSUserDefaults\b",
    "파일 시간 정보": (
        r"creationDate|modificationDate|fileModificationDate|fileCreationDate|"
        r"NSFileCreationDate|NSFileModificationDate|\bstat\(|\bfstat\(|\blstat\(|getattrlist|"
        r"\.contentModificationDateKey|\.creationDateKey"
    ),
    "시스템 부팅 시간": r"systemUptime|mach_absolute_time|\bkern\.boottime\b|clock_gettime_nsec_np",
    "디스크 여유 공간": (
        r"volumeAvailableCapacity|volumeTotalCapacity|systemFreeSize|NSFileSystemFreeSize|"
        r"NSFileSystemSize|\bstatfs\(|\bstatvfs\(|getattrlist"
    ),
    "활성 키보드": r"activeInputModes",
}


def swift_like_files(directory: Path):
    for suffix in ("*.swift", "*.m", "*.mm", "*.h", "*.c", "*.cpp"):
        yield from directory.rglob(suffix)


def scan(directory: Path):
    """{범주: [(파일, 줄번호, 줄)]}"""
    found: dict[str, list[tuple[Path, int, str]]] = {name: [] for name in CATEGORIES}
    for path in swift_like_files(directory):
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for number, line in enumerate(text.splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            for name, pattern in CATEGORIES.items():
                if re.search(pattern, line):
                    found[name].append((path, number, stripped[:120]))
    return {name: rows for name, rows in found.items() if rows}


def plugin_dirs():
    deps = ROOT / ".flutter-plugins-dependencies"
    if not deps.exists():
        print("`.flutter-plugins-dependencies`가 없다. 먼저 `flutter pub get`을 실행하세요.", file=sys.stderr)
        return {}
    data = json.loads(deps.read_text(encoding="utf-8"))
    result = {}
    for entry in data.get("plugins", {}).get("ios", []):
        base = Path(entry["path"])
        # 일부 플러그인은 iOS 소스를 darwin/ 에 둔다
        for sub in ("ios", "darwin"):
            if (base / sub).is_dir():
                result[entry["name"]] = base / sub
                break
    return result


def main() -> int:
    show_lines = "--lines" in sys.argv
    targets = {
        "앱 Runner": ROOT / "ios" / "Runner",
        "워치 앱": ROOT / "ios" / "ShareRunWatch Watch App",
    }
    plugins = plugin_dirs()
    for name, directory in sorted(plugins.items()):
        targets[f"플러그인 {name}"] = directory

    print(f"{'대상':44} {'플러그인 매니페스트':18} 필수 사유 API 후보")
    summary = []
    for name, directory in targets.items():
        if not directory.exists():
            continue
        has_manifest = any(directory.rglob("PrivacyInfo.xcprivacy"))
        found = scan(directory)
        manifest = "있음" if has_manifest else ("해당 없음" if name.startswith("앱") or name.startswith("워치") else "없음")
        cats = ", ".join(f"{cat}({len(rows)})" for cat, rows in found.items()) or "-"
        print(f"{name:44} {manifest:18} {cats}")
        summary.append((name, has_manifest, found))
        if show_lines:
            for cat, rows in found.items():
                for path, number, line in rows:
                    print(f"    [{cat}] {path.relative_to(directory) if directory in path.parents else path}:{number}  {line}")

    needs_app_level = [
        name
        for name, has_manifest, found in summary
        if found and not has_manifest and name.startswith("플러그인")
    ]
    print()
    if needs_app_level:
        print("매니페스트가 없는데 후보 API를 쓰는 플러그인(앱 쪽 매니페스트에서 선언해야 할 수 있음):")
        for name in needs_app_level:
            print("  -", name)
    else:
        print("매니페스트가 없으면서 후보 API를 쓰는 플러그인: 없음")
    return 0


if __name__ == "__main__":
    sys.exit(main())
