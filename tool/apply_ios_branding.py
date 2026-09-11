#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "ios"
INFO = IOS / "Runner" / "Info.plist"
ASSETS = IOS / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ICON_SRC = ROOT / "native_ios" / "AppIcon.appiconset"
OVERLAY = ROOT / "native_ios" / "Info.plist.overlay"


def merge_plist() -> None:
    if not INFO.exists():
        raise SystemExit(f"missing {INFO}")
    with INFO.open("rb") as fh:
        data = plistlib.load(fh)
    overlay: dict = {}
    if OVERLAY.exists():
        with OVERLAY.open("rb") as fh:
            overlay = plistlib.load(fh)
    data.update(overlay)
    data["CFBundleDisplayName"] = "XsTools"
    data["CFBundleName"] = "XsTools"
    data["CFBundleShortVersionString"] = "1.1.1"
    with INFO.open("wb") as fh:
        plistlib.dump(data, fh, sort_keys=False)
    print(f"updated {INFO}")


def patch_pbxproj() -> None:
    pbx = IOS / "Runner.xcodeproj" / "project.pbxproj"
    if not pbx.exists():
        return
    text = pbx.read_text(encoding="utf-8")
    text = re.sub(
        r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;",
        "IPHONEOS_DEPLOYMENT_TARGET = 16.0;",
        text,
    )
    if "INFOPLIST_KEY_CFBundleDisplayName" not in text:
        text = text.replace(
            "GENERATE_INFOPLIST_FILE = YES;",
            'GENERATE_INFOPLIST_FILE = YES;\n\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "XsTools";',
        )
    pbx.write_text(text, encoding="utf-8")
    print(f"patched {pbx}")


def patch_podfile() -> None:
    podfile = IOS / "Podfile"
    if not podfile.exists():
        raise SystemExit(f"missing {podfile}")
    text = podfile.read_text(encoding="utf-8")
    if re.search(r"^platform :ios,", text, flags=re.M):
        text = re.sub(r"^platform :ios,.*$", "platform :ios, '16.0'", text, flags=re.M)
    elif re.search(r"^#\s*platform :ios,", text, flags=re.M):
        text = re.sub(r"^#\s*platform :ios,.*$", "platform :ios, '16.0'", text, flags=re.M)
    else:
        text = "platform :ios, '16.0'\n" + text
    podfile.write_text(text, encoding="utf-8")
    print(f"patched {podfile} -> iOS 16.0")


def copy_icon() -> None:
    if not ICON_SRC.exists():
        raise SystemExit(f"missing {ICON_SRC}")
    ASSETS.mkdir(parents=True, exist_ok=True)
    for item in ICON_SRC.iterdir():
        target = ASSETS / item.name
        if item.is_file():
            shutil.copy2(item, target)
    print(f"copied icons into {ASSETS}")


def main() -> None:
    merge_plist()
    patch_pbxproj()
    patch_podfile()
    copy_icon()


if __name__ == "__main__":
    main()
