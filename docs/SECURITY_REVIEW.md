# Mobile release security review

Candidate: 0.4.2+19, review date 2026-09-08. The cross-project scope,
OpenWrt conformance matrix and remaining release gates are maintained in
[core's release review](https://github.com/owrtpc/core/blob/main/docs/RELEASE_REVIEW.md).

## Security behavior

An unpaired endpoint uses normal CA trust. Once explicitly paired, its exact
host/port certificate pin is enforced during TLS even when a replacement would
be trusted by the operating system. Trust changes close the old connection
pool. A failed pin-storage operation does not activate the new pin. Pairing
inspection sends no credentials; the user must compare the fingerprint with
the router through an independently trusted channel.

Credential-bearing requests require HTTPS, refuse redirects, cap the streamed
response at 1 MiB and enforce an overall deadline. Anonymous endpoint discovery
is separately limited to 64 KiB and bounded time. Real TLS tests cover changed
pins, normal CA trust, pooling, oversized responses and slow continuous output.

Sessions remain in memory. Remembered credentials are opt-in, use iOS
device-bound, non-synchronizing Keychain or Android encrypted storage, and are
removed on logout. Android prohibits backups and uses `FLAG_SECURE`, including
blocking screenshots/screen recordings. iOS hides the inactive scene behind an
opaque cover; this is not an iOS screenshot prohibition. These native privacy
behaviors still require physical-device acceptance.

## Automated evidence

- Full localization/format/analyzer checks and 117 Flutter tests pass locally.
- iOS Profile compilation passes; compilation alone does not verify storage,
  Home launch or background snapshots on a device.
- OSV: no known vulnerabilities in 67 pub-lock packages and 53 Maven runtime
  dependencies resolved by Gradle on the review date. The two iOS plugin Swift
  manifests use local pub-locked sources/Flutter without remote Swift packages.
- Full Git history secret scan: one exact deterministic widget fixture was
  reviewed and allowlisted; no production secret finding remains.
- CI repeats history/pub scanning and scans the resolved Android CycloneDX
  inventory after the native APK/AAB signing and metadata checks. Actions and
  downloaded scanners are pinned to commits or SHA-256 digests.

Run `./tool/check.sh` for shared checks. On native Linux x64 run
`sh tool/security-check.sh`; `./tool/android.sh check` also creates
`build/android-test/dependencies.cdx.json`, which can be supplied using
`sh tool/security-check.sh --sbom build/android-test/dependencies.cdx.json`.
Test-signed artifacts are never release artifacts.

This is an internal review, not an independent penetration test. OSV does not
prove absence of unknown flaws and does not audit Apple/Android system code or
Flutter engine binaries. Privacy/licence/support surfaces, physical security
acceptance, production signing and beta distribution remain M4 work.

Report suspected vulnerabilities privately using the repository Security tab;
do not include credentials or personal router data in a public issue.

## M4 privacy and support increment — 0.5.0+21

M3 was accepted by the owner on 2026-09-08. Remaining physical release/security
checks stay in M4; the milestone decision does not invent individual test results.

The app now provides offline EN/IT privacy and connection/certificate guidance
before login and in Settings, plus a public [privacy notice](PRIVACY.md) and
[private vulnerability reporting policy](../SECURITY.md). Both repository private
reporting forms were verified enabled on 2026-09-08.

Support diagnostics use an explicit field allowlist: numeric app/build/backend
versions, platform, access level, API compatibility and known capability booleans.
Unknown/custom version strings and feature names are omitted. No raw errors,
router addresses, usernames, tokens, certificate fingerprints, profiles, device
identifiers, dates or timezone data are exported. An in-app preview precedes the
explicit clipboard action; there is no automatic upload or new dependency.
Clipboard errors display fixed local copy rather than raw platform details.

Eight new tests cover privacy/help access before login in EN/IT at 200% text,
diagnostics preview/copy, clipboard failure and hostile/private metadata. The
complete shared checks pass locally: localization, formatting, analyzer and 127
Flutter tests. Native device/clipboard behavior, store declarations and final
pre-publication scans remain release gates.
