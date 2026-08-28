#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$PROJECT_DIR"

./tool/flutter.sh pub get
./tool/flutter.sh gen-l10n

untranslated=$(tr -d '[:space:]' < build/untranslated_messages.json)
[ "$untranslated" = '{}' ] || {
	echo "Missing translations: $untranslated" >&2
	exit 1
}

./tool/dart.sh format --output=none --set-exit-if-changed lib test
./tool/flutter.sh analyze
./tool/flutter.sh test
