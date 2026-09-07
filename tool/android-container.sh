#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -eu
exec 9>/workspace/.android-build.lock
flock 9
rsync -a --delete \
    --exclude=.android-build.lock --exclude=.git --exclude=.flutter-sdk \
    --exclude=.dart_tool --exclude=.gradle --exclude=build --exclude=coverage \
    --exclude=ios/Pods --exclude=android/local.properties \
    --exclude='*.jks' --exclude='*.keystore' --exclude='*.p12' --exclude='*.pfx' \
    --exclude=release.properties --exclude=key.properties \
    /source/ /workspace/
cd /workspace
if [ "${1:-}" = check ]; then
    sh tool/check-android-container.sh
else
    flutter "$@"
fi
if [ -d build/app/outputs ]; then
    cp -R build/app/outputs/. /output/
fi
