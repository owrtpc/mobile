# Mobile operational rules

## Versioning and delivery (mandatory)

- Every mobile modification that is committed and pushed must also increment
  the build number in `pubspec.yaml`; never reuse a build number for different
  committed source.
- Follow Semantic Versioning for the public app version: fixes increment PATCH,
  backward-compatible features increment MINOR and incompatible changes
  increment MAJOR. The separate integer build number is not a substitute for
  the semantic version.
- Run the full project checks before committing.
- Commit and push the version bump together with the related modification
  whenever possible. If a bump was missed, use the next build number implied
  by the intervening commits; do not reuse skipped build identities.
- Device installations intended for normal use must be signed profile or
  release builds. Do not install debug builds as user-facing updates.
- After installing on a device, verify that the displayed version and build
  number match `pubspec.yaml` and that the app launches from the Home screen.
