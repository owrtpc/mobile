#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
IMAGE=${OWRTPC_FLUTTER_IMAGE:-owrtpc-mobile-flutter:3.47.2}
PUB_CACHE_VOLUME=${OWRTPC_PUB_CACHE_VOLUME:-owrtpc-mobile-pub-cache}

docker image inspect "$IMAGE" >/dev/null 2>&1 ||
	docker build --platform linux/amd64 -t "$IMAGE" "$PROJECT_DIR"
docker volume create "$PUB_CACHE_VOLUME" >/dev/null

exec docker run --rm --platform linux/amd64 \
	--entrypoint dart \
	-v "$PROJECT_DIR:/workspace" \
	-v "$PUB_CACHE_VOLUME:/root/.pub-cache" \
	-w /workspace \
	"$IMAGE" "$@"
