#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Native Linux x64 CI; optional OSV arguments can include a native --sbom file.
set -eu
cd "$(dirname "$0")/.."
work=$(mktemp -d /tmp/owrtpc-security.XXXXXX)
trap 'rm -rf "$work"' EXIT
curl -fsSL --retry 3 https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz -o "$work/gitleaks.tar.gz"
echo "551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb  $work/gitleaks.tar.gz" | sha256sum -c -
tar -xzf "$work/gitleaks.tar.gz" -C "$work"
"$work/gitleaks" git . --redact --log-opts=--all
curl -fsSL --retry 3 https://github.com/google/osv-scanner/releases/download/v2.5.1/osv-scanner_linux_amd64 -o "$work/osv-scanner"
echo "f9f25499a2c8cc367b3af45df2ea7eeca7fbccceab9c35079968f4b3652194be  $work/osv-scanner" | sha256sum -c -
chmod 0755 "$work/osv-scanner"
"$work/osv-scanner" scan source --lockfile pubspec.lock "$@"
