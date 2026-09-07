#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Run only inside the dedicated Android CI/development image. Never distribute
# the artifacts from this check: their signing identity is temporary test data.
set -eu
[ -f /.dockerenv ] || { echo 'Run this check in the Android container' >&2; exit 1; }
cd /workspace
work=$(mktemp -d /tmp/owrtpc-android-check.XXXXXX)
trap 'rm -rf "$work"' EXIT
flutter pub get
flutter gen-l10n
unset OWRTPC_ANDROID_SIGNING_PROPERTIES
if flutter build apk --release --target-platform android-arm64 > "$work/unsigned.log" 2>&1; then
    echo 'FAIL: release build succeeded without explicit signing' >&2
    exit 1
fi
if ! grep -q 'Release signing is required' "$work/unsigned.log"; then
    cat "$work/unsigned.log" >&2
    exit 1
fi
keytool -genkeypair -keystore "$work/test.p12" -storetype PKCS12 \
    -storepass ci-test-only -keypass ci-test-only -alias owrtpc-ci \
    -dname 'CN=OWRTPC CI TEST ONLY' -keyalg RSA -keysize 2048 -validity 1
cat > "$work/release.properties" <<'EOF'
storeFile=test.p12
storePassword=ci-test-only
keyAlias=owrtpc-ci
keyPassword=ci-test-only
EOF
export OWRTPC_ANDROID_SIGNING_PROPERTIES="$work/release.properties"
flutter build apk --release --target-platform android-arm64
apk=build/app/outputs/flutter-apk/app-release.apk
/opt/android-sdk/build-tools/36.0.0/apksigner verify --verbose --print-certs "$apk" > "$work/apk-signature.log"
cat "$work/apk-signature.log"
keytool -exportcert -keystore "$work/test.p12" -storepass ci-test-only \
    -alias owrtpc-ci -file "$work/certificate.der" > /dev/null
expected_signer=$(sha256sum "$work/certificate.der" | cut -d' ' -f1)
grep -qx "Signer #1 certificate SHA-256 digest: $expected_signer" "$work/apk-signature.log"
apkanalyzer manifest application-id "$apk" | grep -qx org.owrtpc.mobile
expected_name=$(sed -n 's/^version: \([^+]*\)+.*/\1/p' pubspec.yaml)
expected_build=$(sed -n 's/^version: .*+\([0-9]*\).*/\1/p' pubspec.yaml)
[ "$(apkanalyzer manifest version-name "$apk")" = "$expected_name" ]
[ "$(apkanalyzer manifest version-code "$apk")" = "$expected_build" ]
flutter build appbundle --release --target-platform android-arm64
jarsigner -verify build/app/outputs/bundle/release/app-release.aab > "$work/bundle-signature.log"
grep -q 'jar verified' "$work/bundle-signature.log"
bundle_signer=$(keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab \
    | sed -n 's/^[[:space:]]*SHA256: //p' | tr -d ':' | tr '[:upper:]' '[:lower:]')
[ "$bundle_signer" = "$expected_signer" ]
echo 'PASS: unsigned release refusal, temporary signed APK/AAB, package identity and version metadata'
echo 'TEST ARTIFACTS ONLY: do not distribute or install as normal user updates'
