# Security Policy

## Supported versions

Desktop Pet is in pre-release development. Security fixes are applied to the
latest revision of the default branch; older commits and QA artifacts are not
supported releases.

## Reporting a vulnerability

Do not disclose a vulnerability, privacy issue, exposed credential, or signing
material in a public issue.

Use the repository's private vulnerability-reporting option under
**Security → Report a vulnerability** when it is available. Otherwise, contact
the maintainer through the GitHub profile associated with this repository and
request a private reporting channel before sending sensitive details.

Include the affected revision and platform, reproduction steps, expected and
actual behavior, and the potential impact. Please allow reasonable time for a
fix before public disclosure.

## Data and credentials

The game stores player progress locally in Godot's `user://` directory and does
not require an online account. Signing certificates, API keys, passwords,
provisioning data, and decoded keychains must never be committed to this
repository or uploaded as ordinary workflow artifacts.
