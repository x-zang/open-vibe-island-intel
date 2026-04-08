import Foundation
import Testing
@testable import OpenIslandCore

struct HooksBinaryLocatorTests {
    @Test
    func locateFindsBundledHelperBinaryInsideAppBundle() throws {
        let rootURL = temporaryRootURL(named: "hooks-binary-locator")
        let executableDirectory = rootURL
            .appendingPathComponent("Open Island.app", isDirectory: true)
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("MacOS", isDirectory: true)
        let helperBinaryURL = rootURL
            .appendingPathComponent("Open Island.app", isDirectory: true)
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("OpenIslandHooks")

        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        try makeExecutable(at: helperBinaryURL, contents: "bundled-helper")

        let locatedURL = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            executableDirectory: executableDirectory,
            environment: [:]
        )

        #expect(locatedURL?.path == helperBinaryURL.standardizedFileURL.path)
    }

    // MARK: - Architecture-specific dev build paths

    @Test
    func locateFindsArm64ReleaseBuildPath() throws {
        let rootURL = temporaryRootURL(named: "arm64-release")
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let binary = rootURL.appendingPathComponent(".build/arm64-apple-macosx/release/OpenIslandHooks")
        try makeExecutable(at: binary, contents: "arm64-release")
        let result = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            managedHooksHomeDirectory: rootURL,
            environment: [:]
        )
        #expect(result?.standardizedFileURL == binary.standardizedFileURL)
    }

    @Test
    func locateFindsX86ReleaseDevBuildPath() throws {
        let rootURL = temporaryRootURL(named: "x86-release")
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let binary = rootURL.appendingPathComponent(".build/x86_64-apple-macosx/release/OpenIslandHooks")
        try makeExecutable(at: binary, contents: "x86-release")
        let result = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            managedHooksHomeDirectory: rootURL,
            environment: [:]
        )
        #expect(result?.standardizedFileURL == binary.standardizedFileURL)
    }

    @Test
    func locateFindsX86DebugDevBuildPath() throws {
        let rootURL = temporaryRootURL(named: "x86-debug")
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let binary = rootURL.appendingPathComponent(".build/x86_64-apple-macosx/debug/OpenIslandHooks")
        try makeExecutable(at: binary, contents: "x86-debug")
        let result = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            managedHooksHomeDirectory: rootURL,
            environment: [:]
        )
        #expect(result?.standardizedFileURL == binary.standardizedFileURL)
    }

    @Test
    func locateFindsGenericReleaseDevBuildPath() throws {
        let rootURL = temporaryRootURL(named: "generic-release")
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let binary = rootURL.appendingPathComponent(".build/release/OpenIslandHooks")
        try makeExecutable(at: binary, contents: "generic-release")
        let result = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            managedHooksHomeDirectory: rootURL,
            environment: [:]
        )
        #expect(result?.standardizedFileURL == binary.standardizedFileURL)
    }

    @Test
    func locateRespectsEnvironmentOverride() throws {
        let rootURL = temporaryRootURL(named: "env-override")
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let binary = rootURL.appendingPathComponent("custom/OpenIslandHooks")
        try makeExecutable(at: binary, contents: "custom")
        let result = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            environment: ["OPEN_ISLAND_HOOKS_BINARY": binary.path]
        )
        #expect(result?.standardizedFileURL == binary.standardizedFileURL)
    }

    // MARK: - Legacy bundled binary

    @Test
    func locateFindsLegacyBundledHelperBinaryInsideAppBundle() throws {
        let rootURL = temporaryRootURL(named: "hooks-binary-locator-legacy")
        let executableDirectory = rootURL
            .appendingPathComponent("Open Island.app", isDirectory: true)
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("MacOS", isDirectory: true)
        let helperBinaryURL = rootURL
            .appendingPathComponent("Open Island.app", isDirectory: true)
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("VibeIslandHooks")

        defer {
            try? FileManager.default.removeItem(at: rootURL)
        }

        try makeExecutable(at: helperBinaryURL, contents: "legacy-bundled-helper")

        let locatedURL = HooksBinaryLocator.locate(
            currentDirectory: rootURL,
            executableDirectory: executableDirectory,
            environment: [:]
        )

        #expect(locatedURL?.path == helperBinaryURL.standardizedFileURL.path)
    }
}

private func temporaryRootURL(named name: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("open-island-\(name)-\(UUID().uuidString)", isDirectory: true)
}

private func makeExecutable(at url: URL, contents: String) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try Data(contents.utf8).write(to: url)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
}
