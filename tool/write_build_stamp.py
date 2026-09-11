#!/usr/bin/env python3
from __future__ import annotations

import os
import plistlib
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAMP = ROOT / "packages" / "ios_inspect" / "ios" / "Classes" / "BuildStamp.generated.swift"
INFO = ROOT / "ios" / "Runner" / "Info.plist"


def git(*args: str) -> str:
    try:
        return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()
    except Exception:
        return ""


def env(name: str, fallback: str = "") -> str:
    return os.environ.get(name, fallback).strip()


def swift_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> None:
    commit = env("CM_COMMIT") or git("rev-parse", "HEAD") or "unknown"
    short = commit[:7]
    branch = env("CM_BRANCH") or git("rev-parse", "--abbrev-ref", "HEAD") or "main"
    build_id = env("BUILD_NUMBER") or env("CM_BUILD_ID") or "0"
    built_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    workflow = env("CM_WORKFLOW_NAME") or "ios-unsigned-ipa"
    instance = env("CM_INSTANCE_TYPE") or "unknown"
    xcode = env("XCODE_VERSION") or "unknown"
    flutter = env("FLUTTER_ROOT") and Path(env("FLUTTER_ROOT")).name or "unknown"

    STAMP.parent.mkdir(parents=True, exist_ok=True)
    STAMP.write_text(
        "enum BuildStamp {\n"
        f'    static let gitCommit = "{swift_escape(commit)}"\n'
        f'    static let gitCommitShort = "{swift_escape(short)}"\n'
        f'    static let buildId = "{swift_escape(build_id)}"\n'
        f'    static let buildNumber = "{swift_escape(build_id)}"\n'
        f'    static let builtAt = "{swift_escape(built_at)}"\n'
        f'    static let branch = "{swift_escape(branch)}"\n'
        f'    static let workflow = "{swift_escape(workflow)}"\n'
        f'    static let repo = "sanjiuyyds/codemagicTest"\n'
        f'    static let instance = "{swift_escape(instance)}"\n'
        f'    static let xcode = "{swift_escape(xcode)}"\n'
        f'    static let flutter = "{swift_escape(flutter)}"\n'
        "}\n",
        encoding="utf-8",
    )
    print(f"wrote {STAMP} build={build_id} commit={short}")

    if INFO.exists():
        with INFO.open("rb") as fh:
            data = plistlib.load(fh)
        data["CFBundleVersion"] = str(build_id)
        data["CFBundleShortVersionString"] = "1.1.2"
        with INFO.open("wb") as fh:
            plistlib.dump(data, fh, sort_keys=False)
        print(f"set CFBundleVersion={build_id}")


if __name__ == "__main__":
    main()
