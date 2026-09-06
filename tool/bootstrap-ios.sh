#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

FLUTTER_VERSION=3.47.2
FLUTTER_SHA256=f456fd6733053d9301828a2e702d6cbec872923126809aa8c48eb0a696d6cc01
FLUTTER_ARCHIVE=flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip
FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/$FLUTTER_ARCHIVE

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
SDK_CACHE=${OWRTPC_FLUTTER_IOS_CACHE:-$PROJECT_DIR/.flutter-sdk}
SDK_DIR=$SDK_CACHE/flutter
ARCHIVE_PATH=$SDK_CACHE/$FLUTTER_ARCHIVE

if [ -x "$SDK_DIR/bin/flutter" ]; then
	installed_version=$(FLUTTER_SUPPRESS_ANALYTICS=true "$SDK_DIR/bin/flutter" --version --machine | sed -n 's/.*"frameworkVersion":[[:space:]]*"\([^"]*\)".*/\1/p')
	if [ "$installed_version" = "$FLUTTER_VERSION" ]; then
		echo "Flutter $FLUTTER_VERSION is already available at $SDK_DIR"
		exit 0
	fi

	echo "Flutter $installed_version already exists at $SDK_DIR; remove or relocate it first." >&2
	exit 1
fi

mkdir -p "$SDK_CACHE"
curl --fail --location --continue-at - "$FLUTTER_URL" --output "$ARCHIVE_PATH"
printf '%s  %s\n' "$FLUTTER_SHA256" "$ARCHIVE_PATH" | shasum -a 256 --check

extract_dir=$(mktemp -d "$SDK_CACHE/extract.XXXXXX")
trap 'rm -rf "$extract_dir"' EXIT HUP INT TERM
unzip -q "$ARCHIVE_PATH" -d "$extract_dir"
mv "$extract_dir/flutter" "$SDK_DIR"
rm -f "$ARCHIVE_PATH"

FLUTTER_SUPPRESS_ANALYTICS=true "$SDK_DIR/bin/flutter" --version
