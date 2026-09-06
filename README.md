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

Android tooling will be added as a separate pinned Docker image layer. Shared
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
increment MAJOR. The integer after `+` is a separate, monotonically increasing
store build identifier required by iOS and Android; it changes for every
committed app build but does not replace the semantic version. For example,
`0.2.0+9` is displayed by iOS as version `0.2.0`, build `9`.

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
Profile deletion remains part of M3.

TLS uses the operating system trust store first. An unknown self-signed
certificate is inspected without sending credentials; the app shows its
SHA-256 fingerprint and pins it for that exact host and port only after explicit
user comparison. Expired, not-yet-valid and changed certificates remain blocked.

The product and security contract is maintained in the sibling core repository
at `../core/docs/MOBILE_APP.md`.

## Licence

Apache License 2.0. See `LICENSE`.
