#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f pubspec.yaml ]; then
  echo "缺少 pubspec.yaml"
  exit 1
fi

if [ ! -f ios/Runner.xcodeproj/project.pbxproj ]; then
  echo "仓库没有 ios 工程，由云端补全 iOS 平台文件"
  cp pubspec.yaml /tmp/ipa_min_pubspec.yaml
  mkdir -p /tmp/ipa_min_lib
  cp -R lib/. /tmp/ipa_min_lib/
  flutter create . --project-name ipa_min --org com.sanjiuyyds --platforms=ios
  cp /tmp/ipa_min_pubspec.yaml pubspec.yaml
  mkdir -p lib
  cp -R /tmp/ipa_min_lib/. lib/
fi

python3 "$ROOT/tool/apply_ios_branding.py"
python3 "$ROOT/tool/write_build_stamp.py"

flutter pub get
(cd ios && pod install)
