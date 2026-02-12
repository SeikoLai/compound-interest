#!/usr/bin/env bash
set -euo pipefail

PROJECT="Compound Interest.xcodeproj"
SCHEME="Compound Interest"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17 Pro Max}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "[ERROR] xcodebuild not found. Please install Xcode command line tools."
  exit 1
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "[ERROR] Project not found: $PROJECT"
  exit 1
fi

echo "[INFO] Running pre-refactor guardrail checks..."
echo "[INFO] Project: $PROJECT"
echo "[INFO] Scheme:  $SCHEME"
echo "[INFO] Destination: $DESTINATION"

echo
echo "[STEP 1/2] build-for-testing"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  build-for-testing

echo
echo "[STEP 2/2] test-without-building"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  test-without-building

echo
echo "[OK] Guardrail checks passed."
