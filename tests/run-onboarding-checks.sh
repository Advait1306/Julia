#!/bin/zsh
set -eu

# Run from any directory. All credentials used here are synthetic and isolated
# with UUID service names; the request stub never contacts Jev.
project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${1:-/tmp/julia-onboarding-build}"
test_dir="$(mktemp -d /tmp/julia-onboarding-checks.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
cd "$project_root"

if ! xcodebuild -project julia.xcodeproj -scheme julia -destination 'platform=macOS' \
    -derivedDataPath "$build_dir" CODE_SIGNING_ALLOWED=NO build > "$test_dir/build.log" 2>&1; then
    cat "$test_dir/build.log"
    exit 1
fi
print 'PASS: macOS app build'
xcrun swiftc -parse-as-library -target "$(uname -m)-apple-macos27.0" \
    julia/HotkeyManager.swift tests/HotkeyStateTests.swift -o "$test_dir/hotkey-state-tests"
"$test_dir/hotkey-state-tests"
xcrun swiftc -parse-as-library -target "$(uname -m)-apple-macos27.0" \
    julia/ui/settings/NativeAPIKeyField.swift tests/NativeAPIKeyFieldTests.swift \
    -o "$test_dir/native-key-field-tests"
"$test_dir/native-key-field-tests"
xcrun swiftc julia/security/JevKeychain.swift tests/KeychainTests.swift -o "$test_dir/keychain-tests"
"$test_dir/keychain-tests"

products="$build_dir/Build/Products/Debug"
fluid="$build_dir/SourcePackages/checkouts/FluidAudio/Sources"
xcrun swiftc -parse-as-library \
    -I "$products" -I "$products/include" \
    -I "$fluid/MachTaskSelfWrapper/include" -I "$fluid/FastClusterWrapper/include" \
    tests/JevCredentialTests.swift "$products/julia.app/Contents/MacOS/julia.debug.dylib" \
    -o "$test_dir/jev-tests"
DYLD_LIBRARY_PATH="$products/julia.app/Contents/MacOS:$products" "$test_dir/jev-tests"
