# Intel macOS Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure the app builds and runs correctly on Intel (x86_64) Macs by fixing hardcoded arm64 build paths in `HooksBinaryLocator.swift`.

**Architecture:** The only code-level incompatibility is in `HooksBinaryLocator.swift`, which hardcodes `.build/arm64-apple-macosx/` paths as dev-build candidates. On Intel Macs, Swift Package Manager outputs to `.build/x86_64-apple-macosx/`. Generic fallback paths (`.build/release/`, `.build/debug/`) already exist and cover Intel, but the architecture-specific shortcuts should be extended for consistency and correctness. No other code changes are needed — the app already handles non-notch displays gracefully via `OverlayPlacementMode.topBar`.

**Tech Stack:** Swift 6.2, Swift Package Manager, macOS 14+, XCTest

---

## File Map

| File | Change |
|------|--------|
| `Sources/OpenIslandCore/HooksBinaryLocator.swift` | Add `x86_64-apple-macosx` candidate paths alongside existing `arm64-apple-macosx` paths |
| `Tests/OpenIslandCoreTests/HooksBinaryLocatorTests.swift` | New test file: verify locator finds binaries under both arch-specific and generic paths |

---

### Task 1: Test the current behaviour on Intel paths

**Files:**
- Create: `Tests/OpenIslandCoreTests/HooksBinaryLocatorTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/OpenIslandCoreTests/HooksBinaryLocatorTests.swift`:

```swift
import XCTest
@testable import OpenIslandCore

final class HooksBinaryLocatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeTempDir() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func touch(executableAt url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data().write(to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    // MARK: - arm64 path (existing behaviour)

    func test_locatesHooksUnderArm64ReleasePath() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }

        let binary = root
            .appendingPathComponent(".build/arm64-apple-macosx/release/OpenIslandHooks")
        try touch(executableAt: binary)

        let result = HooksBinaryLocator.locate(currentDirectory: root, environment: [:])
        XCTAssertEqual(result?.standardizedFileURL, binary.standardizedFileURL)
    }

    func test_locatesHooksUnderArm64DebugPath() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }

        let binary = root
            .appendingPathComponent(".build/arm64-apple-macosx/debug/OpenIslandHooks")
        try touch(executableAt: binary)

        let result = HooksBinaryLocator.locate(currentDirectory: root, environment: [:])
        XCTAssertEqual(result?.standardizedFileURL, binary.standardizedFileURL)
    }

    // MARK: - x86_64 path (new behaviour, currently fails)

    func test_locatesHooksUnderX86ReleasePath() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }

        let binary = root
            .appendingPathComponent(".build/x86_64-apple-macosx/release/OpenIslandHooks")
        try touch(executableAt: binary)

        let result = HooksBinaryLocator.locate(currentDirectory: root, environment: [:])
        XCTAssertEqual(result?.standardizedFileURL, binary.standardizedFileURL)
    }

    func test_locatesHooksUnderX86DebugPath() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }

        let binary = root
            .appendingPathComponent(".build/x86_64-apple-macosx/debug/OpenIslandHooks")
        try touch(executableAt: binary)

        let result = HooksBinaryLocator.locate(currentDirectory: root, environment: [:])
        XCTAssertEqual(result?.standardizedFileURL, binary.standardizedFileURL)
    }

    // MARK: - Generic fallback (ensures fallback still works)

    func test_locatesHooksUnderGenericReleasePath() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }

        let binary = root
            .appendingPathComponent(".build/release/OpenIslandHooks")
        try touch(executableAt: binary)

        let result = HooksBinaryLocator.locate(currentDirectory: root, environment: [:])
        XCTAssertEqual(result?.standardizedFileURL, binary.standardizedFileURL)
    }

    // MARK: - Environment override

    func test_environmentVariableOverridesAllCandidates() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }

        let envBinary = root.appendingPathComponent("custom/hooks")
        try touch(executableAt: envBinary)

        let result = HooksBinaryLocator.locate(
            currentDirectory: root,
            environment: ["OPEN_ISLAND_HOOKS_BINARY": envBinary.path]
        )
        XCTAssertEqual(result?.standardizedFileURL, envBinary.standardizedFileURL)
    }
}
```

- [ ] **Step 2: Run the tests to confirm x86_64 tests fail**

```bash
swift test --filter HooksBinaryLocatorTests 2>&1 | tail -30
```

Expected output: `test_locatesHooksUnderX86ReleasePath` and `test_locatesHooksUnderX86DebugPath` **FAIL**; arm64 and generic tests **PASS**.

- [ ] **Step 3: Commit the failing tests**

```bash
git add Tests/OpenIslandCoreTests/HooksBinaryLocatorTests.swift
git commit -m "test: add HooksBinaryLocator tests covering x86_64 paths (red)"
```

---

### Task 2: Fix HooksBinaryLocator to include x86_64 paths

**Files:**
- Modify: `Sources/OpenIslandCore/HooksBinaryLocator.swift:109-118`

- [ ] **Step 1: Open the file and locate the candidate list**

Read `Sources/OpenIslandCore/HooksBinaryLocator.swift` lines 100–125. The relevant block is:

```swift
// BEFORE (lines ~109-118):
] + ManagedHooksBinary.candidateURLs(fileManager: fileManager) + [
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/release/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/release/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/release/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/release/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/debug/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/debug/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/debug/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/debug/VibeIslandHooks"),
]
```

- [ ] **Step 2: Replace the candidate block with arch-agnostic equivalents**

Replace the block above with:

```swift
] + ManagedHooksBinary.candidateURLs(fileManager: fileManager) + [
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/release/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/x86_64-apple-macosx/release/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/release/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/release/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/x86_64-apple-macosx/release/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/release/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/debug/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/x86_64-apple-macosx/debug/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/debug/OpenIslandHooks"),
    currentDirectory.appendingPathComponent(".build/arm64-apple-macosx/debug/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/x86_64-apple-macosx/debug/VibeIslandHooks"),
    currentDirectory.appendingPathComponent(".build/debug/VibeIslandHooks"),
]
```

- [ ] **Step 3: Build to verify no compilation errors**

```bash
swift build 2>&1 | tail -10
```

Expected: `Build complete!`

- [ ] **Step 4: Run all HooksBinaryLocator tests — all should pass**

```bash
swift test --filter HooksBinaryLocatorTests 2>&1 | tail -20
```

Expected: All 6 tests **PASS**.

- [ ] **Step 5: Run the full test suite**

```bash
swift test 2>&1 | tail -20
```

Expected: All tests **PASS** (no regressions).

- [ ] **Step 6: Commit the fix**

```bash
git add Sources/OpenIslandCore/HooksBinaryLocator.swift
git commit -m "fix: add x86_64-apple-macosx candidate paths to HooksBinaryLocator for Intel Mac compatibility"
```

---

### Task 3: Push and open PR

- [ ] **Step 1: Push the branch**

```bash
git push -u origin HEAD
```

- [ ] **Step 2: Create the PR**

```bash
gh pr create \
  --title "fix: Intel Mac compatibility in HooksBinaryLocator" \
  --body "$(cat <<'EOF'
## Summary
- Adds `x86_64-apple-macosx` build path candidates to `HooksBinaryLocator` so the hooks binary is found on Intel Macs during local development
- Adds unit tests covering arm64, x86_64, generic fallback, and env-override paths

## Why
Swift Package Manager outputs to `.build/x86_64-apple-macosx/` on Intel. Only `arm64-apple-macosx` paths were listed; generic `.build/release/` fallbacks existed but arch-specific shortcuts were silent no-ops on Intel.

## Test plan
- [ ] `swift test --filter HooksBinaryLocatorTests` passes on both Apple Silicon and Intel
- [ ] `swift build` succeeds on both architectures
- [ ] Verified no behavioural change on arm64 (arm64 paths still listed first)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Notes

- No UI or logic changes are required — the notch-vs-topBar fallback (`OverlayDisplayConfiguration.swift:142-150`) already handles Intel Macs (no notch) correctly.
- macOS 14 minimum (`Package.swift:9`) is supported on Intel Macs from 2017 onwards.
- Sparkle 2.x is a universal binary; no changes needed there.
