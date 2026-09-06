#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
FLUTTER_IOS_SDK=${OWRTPC_FLUTTER_IOS_SDK:-$PROJECT_DIR/.flutter-sdk/flutter}
PUB_CACHE=${OWRTPC_FLUTTER_IOS_PUB_CACHE:-$PROJECT_DIR/.flutter-sdk/pub-cache}
FLUTTER_SUPPRESS_ANALYTICS=${FLUTTER_SUPPRESS_ANALYTICS:-true}
export FLUTTER_SUPPRESS_ANALYTICS PUB_CACHE

if [ ! -x "$FLUTTER_IOS_SDK/bin/flutter" ]; then
	echo "Flutter macOS SDK not found at $FLUTTER_IOS_SDK" >&2
	echo "Run ./tool/bootstrap-ios.sh or set OWRTPC_FLUTTER_IOS_SDK." >&2
	exit 1
fi

exec "$FLUTTER_IOS_SDK/bin/flutter" "$@"
