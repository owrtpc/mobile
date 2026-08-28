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

Android tooling will be added as a separate pinned Docker image layer. iOS
project files can be generated and most shared Dart code can be tested in the
container, but compiling, signing and running the iOS target still requires
macOS and Xcode.

The Flutter image uses the official 3.47.2 Linux archive and verifies its
published SHA-256 before extraction. CI builds the same image and rejects
missing Italian/English translations, formatting drift, analyzer findings and
test failures.

## Current connection slice

The app accepts router hosts only over HTTPS, calls the ubus JSON-RPC bridge at
`/ubus`, performs `session.login`, checks read and quick-action ACLs, validates
`owrtpc.capabilities` V1 and keeps the returned session only in memory. Logout
best-effort destroys the router session. Read-only accounts do not see write
controls.

TLS currently uses the operating system trust store without bypasses. Explicit
pairing for the self-signed certificates commonly used by OpenWrt remains an M0
security task; until it is implemented, such a router is intentionally rejected
instead of sending credentials over an unverified connection.

The product and security contract is maintained in the sibling core repository
at `../core/docs/MOBILE_APP.md`.

## Licence

Apache License 2.0. See `LICENSE`.
