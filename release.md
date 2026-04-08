# Release Notes

## Building for Distribution

### Universal Binary (Fat Binary)

Build a universal binary that runs natively on both Apple Silicon (arm64) and Intel (x86_64) Macs:

```bash
swift build -c release --arch arm64 --arch x86_64
```

Output is at `.build/apple/Products/Release/`.

All three executables must be built as universal:
- `OpenIslandApp` — main app
- `OpenIslandHooks` — hook CLI invoked by agents (critical)
- `OpenIslandSetup` — installer CLI

Verify after building:

```bash
lipo -info .build/apple/Products/Release/OpenIslandHooks
# Expected: Architectures in the fat file: arm64 x86_64
```

### Code Signing and Notarization

macOS Gatekeeper will block unsigned binaries on user machines. Before distributing:

1. Sign with a Developer ID certificate
2. Notarize with Apple
