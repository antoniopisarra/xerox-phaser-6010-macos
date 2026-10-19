# Release procedure

1. Update VERSION, changelog and user documentation. Run the documented checks; record physical tests separately.
2. Build the package and verify its payload, ARM64 binaries, dependencies, application signature and included source/licenses. Ensure calibration files are absent from the payload.
3. Run `./scripts/release-assets.sh` from a clean committed checkout. It exports tracked source plus the original Ghostscript archive, copies both calibration PDFs and creates SHA256SUMS in dist/. Do not include user logs, documents, IP addresses or build caches.
4. Tag the tested commit and publish the package, corresponding-source archive, two PDFs and checksums as a GitHub release. No beta/prerelease label is required. State the actual unsigned/unnotarized distribution status and remaining Mac checks.

## Optional Apple distribution signing

The current scripts intentionally produce an ad hoc signed app and unsigned package. No signing credentials are included or required. For a future notarized distribution, the maintainer must sign all executable payloads with their own Developer ID Application certificate and appropriate hardened-runtime settings, sign the installer with Developer ID Installer, submit it to Apple's notary service, staple the accepted ticket and verify it on a downloaded package. Review resource/signature changes carefully; never claim notarization based on an ad hoc signature or successful local launch. Secrets belong in a credential store, not this repository.
