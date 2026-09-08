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
