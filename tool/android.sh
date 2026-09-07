#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
IMAGE=owrtpc-mobile-android:37-v1
docker image inspect owrtpc-mobile-flutter:3.47.2 >/dev/null 2>&1 ||
    docker build --platform linux/amd64 -t owrtpc-mobile-flutter:3.47.2 "$PROJECT_DIR"
docker build --platform linux/amd64 -t "$IMAGE" -f "$PROJECT_DIR/docker/android.Dockerfile" "$PROJECT_DIR"
docker volume create owrtpc-mobile-pub-cache >/dev/null
docker volume create owrtpc-mobile-gradle-cache >/dev/null
WORKSPACE_VOLUME=owrtpc-mobile-android-production
OUTPUT_DIR="$PROJECT_DIR/build/android"
if [ "${1:-}" = check ]; then
    WORKSPACE_VOLUME=owrtpc-mobile-android-workspace
    OUTPUT_DIR="$PROJECT_DIR/build/android-test"
fi
docker volume create "$WORKSPACE_VOLUME" >/dev/null
mkdir -p "$OUTPUT_DIR"

if [ -n "${OWRTPC_ANDROID_SIGNING_DIR:-}" ]; then
    [ -r "$OWRTPC_ANDROID_SIGNING_DIR/release.properties" ] || {
        echo 'Android signing directory must contain readable release.properties' >&2
        exit 1
    }
    exec docker run --rm --platform linux/amd64 \
        -v "$PROJECT_DIR:/source:ro" -v "$OUTPUT_DIR:/output" \
        -v "$WORKSPACE_VOLUME:/workspace" \
        -v owrtpc-mobile-pub-cache:/root/.pub-cache \
        -v owrtpc-mobile-gradle-cache:/root/.gradle \
        -v "$OWRTPC_ANDROID_SIGNING_DIR:/signing:ro" \
        -e OWRTPC_ANDROID_SIGNING_PROPERTIES=/signing/release.properties \
        -w /workspace --entrypoint sh "$IMAGE" /source/tool/android-container.sh "$@"
fi
exec docker run --rm --platform linux/amd64 \
    -v "$PROJECT_DIR:/source:ro" -v "$OUTPUT_DIR:/output" \
    -v "$WORKSPACE_VOLUME:/workspace" \
    -v owrtpc-mobile-pub-cache:/root/.pub-cache \
    -v owrtpc-mobile-gradle-cache:/root/.gradle \
    -w /workspace --entrypoint sh "$IMAGE" /source/tool/android-container.sh "$@"
