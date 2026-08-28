#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

FLUTTER_IOS_SDK=${OWRTPC_FLUTTER_IOS_SDK:-/private/tmp/owrtpc-flutter-ios/flutter}

if [ ! -x "$FLUTTER_IOS_SDK/bin/flutter" ]; then
	echo "Flutter macOS SDK not found at $FLUTTER_IOS_SDK" >&2
	echo "Set OWRTPC_FLUTTER_IOS_SDK to an extracted Flutter 3.47.2 macOS SDK." >&2
	exit 1
fi

exec "$FLUTTER_IOS_SDK/bin/flutter" "$@"
