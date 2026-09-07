# Android builds and release signing

The Android development toolchain is isolated in Docker; no host Android SDK or
JDK is required. `tool/android.sh` builds the Flutter base image if absent and
adds the cached Android image from `docker/android.Dockerfile`.
Sources are copied from a read-only mount into a Linux Docker volume so native
build intermediates stay on a Linux filesystem. Completed outputs
are copied back to the host; concurrent builds share a workspace lock.
Validation and production builds use separate workspaces and output directories
so temporary test certificates and artifacts cannot carry over between them.

## Configured toolchain

| Component | Version |
| --- | --- |
| Flutter | 3.47.2, official archive with verified SHA-256 |
| JDK | Temurin 21.0.12+8, image pinned by digest |
| Android command-line tools | Build 15859902, verified official SHA-256 |
| Compile / target SDK | 37.0 / 36 |
| Minimum SDK | 24 (Android 7.0); physical-device acceptance remains open |
| Build tools | 36.0.0 |
| NDK | 28.2.13676358 |
| CMake | 3.22.1 |
| Android Gradle plugin / Gradle | 9.1.1 / 9.3.1 |

Compile SDK 37 satisfies the existing secure-storage plugin; target SDK 36
retains the Flutter baseline and is a separate setting. Recheck
target SDK and store requirements before submission; this does not claim that
store acceptance or Android 17 permission testing has been completed. The JDK
runs Gradle while Java/Kotlin application bytecode still targets Java 17.
SDK platforms 35 and 36 are also installed for the native plugin builds.

Building the image accepts the standard Android SDK licences. Gradle and pub
downloads use dedicated Docker volumes. Platform tools follow the SDK repository
version at image build time; `/opt/android-sdk/installed-packages.txt` records it.
Pinned tool versions are not a claim of bit-for-bit reproducible APKs across
independently refreshed dependency repositories.

## Development and validation

```sh
./tool/android.sh build apk --debug
./tool/android.sh check
```

Debug APKs are for development only, not normal device updates or public releases.
The container validation script checks that release builds fail without signing,
then builds APK/AAB artifacts using a temporary CI-only certificate and checks
signatures and APK version metadata. Those artifacts must never be distributed.
See the Android CI job for the exact invocation.

Use the native Linux x64 CI runner as the Android release validation environment.
On Apple Silicon, the x64 image runs under emulation: debug compilation has been
verified, but Flutter 3.47.2/Dart 3.13.2 release compilation has failed inside
`File::Copy` with `Unexpected EINTR errno`, including on a Linux Docker volume.
Do not treat that failure as a passed check or distribute partial outputs.

## Production signing

Release builds never fall back to Android debug keys. The maintainer supplies a
durable signing/upload keystore and owns its backup and store registration.
Keep it outside the repository together with a private `release.properties`:

```properties
storeFile=release.p12
storePassword=YOUR_STORE_PASSWORD
keyAlias=YOUR_KEY_ALIAS
keyPassword=YOUR_KEY_PASSWORD
```

`storeFile` is relative to that properties file. Protect both files with owner-only
permissions. Do not paste signing passwords into command-line arguments, commit
these files or reuse the temporary CI certificate. The wrapper mounts the
directory read-only at `/signing`; only its path is passed through the environment.

After source checks, the version/build bump, commit/push and successful CI:

```sh
export OWRTPC_ANDROID_SIGNING_DIR=/absolute/private/android-signing-directory
./tool/android.sh build apk --release
./tool/android.sh build appbundle --release
```

Outputs are `build/android/flutter-apk/app-release.apk` and
`build/android/bundle/release/app-release.aab`. Check artifacts are kept separately
in `build/android-test`. Before distribution, verify
their signer against the registered certificate, record source SHA/toolchain and
checksums, and confirm installed version/build plus Home-screen launch on a
physical device. Do not replace an already distributed version. APK/AAB creation
does not publish to Google Play.

Production signing identity, physical Keystore/LAN/TalkBack acceptance and closed
Play testing remain tracked in [build/signing](https://github.com/owrtpc/mobile/issues/3)
and [distribution](https://github.com/owrtpc/mobile/issues/6).

## Sources checked

- [Official Android command-line tools and checksums](https://developer.android.com/studio#command-tools)
- [Android Gradle plugin 9.1 compatibility](https://developer.android.com/build/releases/agp-9-1-0-release-notes)
- [Sign an Android application](https://developer.android.com/studio/publish/app-signing)
