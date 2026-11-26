#!/usr/bin/env bash
# Runs every check. Builds iOS too when run on macOS.
set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build_logs
log="$PWD/build_logs/verify.log"
: >"$log"
failed=()

step() {
  local name=$1 dir=$2
  shift 2
  echo "=== $name ===" | tee -a "$log"
  (cd "$dir" && "$@") 2>&1 | tee -a "$log"
  [ "${PIPESTATUS[0]}" -eq 0 ] || failed+=("$name")
}

step 'pub get' . flutter pub get
step 'example pub get' example flutter pub get
step 'analyze' . flutter analyze
step 'unit tests' . flutter test
step 'example tests' example flutter test
step 'build Android' example flutter build apk --debug
step 'Kotlin tests' example/android ./gradlew :netpulse_connectivity_sdk:testDebugUnitTest
if [ "$(uname)" = Darwin ]; then
  step 'build iOS' example flutter build ios --simulator --debug
fi

if [ ${#failed[@]} -eq 0 ]; then
  echo 'ALL STEPS PASSED' | tee -a "$log"
else
  echo "FAILED: ${failed[*]}" | tee -a "$log"
  exit 1
fi
