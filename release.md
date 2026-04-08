# Release Notes

Use [`docs/releasing.md`](./docs/releasing.md) as the source-of-truth release process.

## Packaging

Build distribution artifacts through the repo packaging script:

```bash
OPEN_ISLAND_VERSION=<version> \
OPEN_ISLAND_EDDSA_PUBLIC_KEY="<your-public-key>" \
zsh scripts/package-app.sh
```

This produces the packaged app artifacts under `output/package/` and keeps the release flow aligned with:

- Sparkle framework embedding
- app bundle assembly
- signing and notarization steps
- appcast updates
- bilingual release notes requirements

## Architecture Support

The package supports both Apple Silicon and Intel Macs on macOS 14+.
Verify the packaged binaries match the expected architectures before release:

```bash
lipo -info "output/package/Open Island.app/Contents/Helpers/OpenIslandHooks"
```
