# Security policy

## Supported versions

OWRTPC Mobile is preparing its first installable public release. Source releases
and locally signed test installations do not imply availability on an app store.
Security fixes are developed on `main` for subsequent reviewed releases; there
is no long-term support or backport commitment for older versions.

See the [release roadmap](https://github.com/owrtpc/core/blob/main/docs/ROADMAP.md)
and [internal review and its limits](docs/SECURITY_REVIEW.md).

## Private vulnerability reports

Use GitHub's [Report a vulnerability](https://github.com/owrtpc/mobile/security/advisories/new)
form. Private vulnerability reporting is enabled for this repository. For router
backend or LuCI vulnerabilities, use the
[core private reporting form](https://github.com/owrtpc/core/security/advisories/new).

Include the affected app/backend versions, reproduction steps and impact.
Do not include passwords, tokens, private keys, configuration backups or real
router/device identifiers. Use redacted examples where possible. Do not disclose
suspected vulnerabilities in public issues.

The maintainer aims to acknowledge reports within seven days and agree on a
remediation and disclosure timeline after reproducing and assessing the report,
as described in the [project security policy](https://github.com/owrtpc/core/blob/main/SECURITY.md).

Ordinary support requests belong in [project issues](https://github.com/owrtpc/mobile/issues).
Review the diagnostics preview and any screenshots before posting.
