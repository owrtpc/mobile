# OWRTPC Mobile

Flutter companion app for OWRTPC. The router remains the source of truth and
the app connects directly over the local network without an OWRTPC cloud
account.

## Docker-first development

Flutter and Dart are pinned inside the development image. A host Flutter SDK is
not required for project generation, dependency resolution, formatting,
analysis or tests:

```sh
./tool/flutter.sh --version
./tool/flutter.sh pub get
./tool/flutter.sh analyze
./tool/flutter.sh test
./tool/dart.sh format --output=none --set-exit-if-changed lib test
./tool/check.sh
```

Docker Desktop on Apple Silicon runs the official Linux x64 Flutter SDK through
emulation. The named `owrtpc-mobile-pub-cache` volume preserves downloaded Dart
packages without writing a global SDK or package cache onto the Mac.

Android tooling uses a separate pinned Docker image layer; see
[Android builds and signing](docs/ANDROID.md). Shared
Dart code is generated and tested in the container. Compiling, signing and
running the iOS target requires macOS, Xcode, the matching iOS platform and an
Apple Development team. Bootstrap the pinned macOS SDK once into the
project-local, Git-ignored persistent cache, then use it without adding Flutter
to the host `PATH`:

```sh
./tool/bootstrap-ios.sh
./tool/ios.sh doctor -v
./tool/ios.sh build ios --debug --no-codesign
./tool/ios.sh devices
```

The Flutter image uses the official 3.47.2 Linux archive and verifies its
published SHA-256 before extraction. CI builds the same image and rejects
missing Italian/English translations, formatting drift, analyzer findings and
test failures.

## Versioning

The app uses Semantic Versioning for its public version. Backward-compatible
features increment MINOR, fixes increment PATCH and incompatible releases
increment MAJOR. Every committed app modification advances at least PATCH. The
integer after `+` is separate store metadata required by iOS and Android; it is
monotonically increasing but is not shown as the app version. For example,
`0.2.1+11` is displayed in the app as `0.2.1`; the operating system retains
build `11` for installation diagnostics.

## Current profile and quick-action slice

The app accepts router hosts only over HTTPS, calls the ubus JSON-RPC bridge at
`/ubus`, performs `session.login`, checks read and quick-action ACLs, validates
`owrtpc.capabilities` V1 and keeps the returned session only in memory. It then
combines live `owrtpc.status` and committed `uci get owrtpc` data into the
profile list. Users can opt in to remembering the router login in device-bound,
non-synchronizing iOS Keychain or Android Keystore-backed encrypted storage.
The app then signs in automatically at launch and renews an expired in-memory
session without replaying writes. Logout removes the remembered login and
best-effort destroys the router session.

Tapping a profile opens its details: current shared usage and state,
the associated devices with discovered names and addresses, each device's
diagnostic usage, daily allowances, bedtime windows and any profile-specific
activity threshold. Device usage requires the optional API 1.2
`device-usage` data; older backends continue to show the configured devices
without inventing a usage value.

Write-capable accounts can block or unblock a profile, enable or disable it and
replace the temporary extra-time choice with one hour, four hours or all day.
Every write is followed by a fresh status read and is never retried
automatically after an ambiguous result. With a core exposing API 1.3 and
`profile-edit-transaction`, they can also edit an existing profile's name,
enabled state, assigned devices, allowances, bedtime windows and activity
threshold. The app submits a complete revision-bound draft, then verifies both
the committed snapshot and live policy state before reporting success. With API
1.4 and `profile-create-transaction`, users can also create profiles and assign
unassigned devices discovered by the router. Devices already owned by another
profile remain visible but unavailable, preserving exclusive assignment.
With API 1.5 and `profile-delete-transaction`, the detail screen also offers
profile deletion, with a native iOS or Android confirmation explaining the
effect on associated devices. Deletion uses the confirmed snapshot revision,
is submitted once and is reported as successful only after the profile is
absent from both the committed snapshot and live policy status. Read-only
accounts and older backends do not expose deletion. With API 1.6 and
`profile-order-transaction`, write-capable users can reorder profiles using
labelled move-up/down controls and an explicit Apply action. Ordering uses a
revision-bound local draft, is submitted once and is confirmed only after both
the committed snapshot and live status match. A conflict or unconfirmed outcome
requires reopening the screen to load current state before another attempt.

M3 functionality is implemented; physical Android/iOS acceptance remains open.
See the [tracked release roadmap](https://github.com/owrtpc/core/blob/main/docs/ROADMAP.md)
and [mobile milestones](https://github.com/owrtpc/mobile/milestones) for M3/M4
acceptance. Source versions are not proof of public binary distribution: the
existing GitHub mobile release has no installable APK/IPA, and store delivery
is still pending.

Unpaired endpoints use the operating system trust store. An unknown self-signed
certificate is inspected without sending credentials; the app shows its
SHA-256 fingerprint and pins it for that exact host and port only after explicit
user comparison. Expired, not-yet-valid and changed certificates remain blocked.
An existing pin takes precedence over CA trust, and trust changes invalidate
old pooled connections before the next authenticated request. See the
[security review](docs/SECURITY_REVIEW.md) for tested boundaries and release gates.

The product and security contract is maintained in the sibling core repository
at `../core/docs/MOBILE_APP.md`.

## Licence

Apache License 2.0. See `LICENSE`.

Settings includes maintainer credits, [@desmofab](https://github.com/desmofab),
source/licence links and an offline open-source licence sheet.
OWRTPC is independent and not affiliated with OpenWrt. OpenWrt is a registered
trademark owned by Software Freedom Conservancy (SFC); see
[OpenWrt](https://openwrt.org) and its [trademark policy](https://openwrt.org/trademark).
Naming clarification remains a pre-promotion gate in the core release review.
