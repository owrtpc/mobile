#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Native macOS fallback for release compilation affected by Linux emulation.
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
[ "$(uname -s)" = Darwin ] || { echo 'This wrapper requires macOS' >&2; exit 1; }
NATIVE_TOOLS="$PROJECT_DIR/.flutter-sdk/android-native"
ANDROID_HOME=${OWRTPC_ANDROID_MAC_SDK:-"$NATIVE_TOOLS/sdk"}
ANDROID_SDK_ROOT="$ANDROID_HOME"
JAVA_HOME=${OWRTPC_ANDROID_MAC_JDK:-"$NATIVE_TOOLS/jdk/jdk-21.0.12.1+1/Contents/Home"}
GRADLE_USER_HOME="$NATIVE_TOOLS/gradle"
[ -x "$JAVA_HOME/bin/java" ] && [ -d "$ANDROID_HOME/platforms/android-37.0" ] || {
    echo 'Native Android SDK/JDK missing; see docs/ANDROID.md' >&2
    exit 1
}
export JAVA_HOME ANDROID_HOME ANDROID_SDK_ROOT GRADLE_USER_HOME
if [ -n "${OWRTPC_ANDROID_SIGNING_DIR:-}" ]; then
    OWRTPC_ANDROID_SIGNING_PROPERTIES="$OWRTPC_ANDROID_SIGNING_DIR/release.properties"
    [ -r "$OWRTPC_ANDROID_SIGNING_PROPERTIES" ] || {
        echo 'Android signing directory must contain readable release.properties' >&2
        exit 1
    }
    export OWRTPC_ANDROID_SIGNING_PROPERTIES
fi
cd "$PROJECT_DIR"
exec "$PROJECT_DIR/tool/ios.sh" "$@"
