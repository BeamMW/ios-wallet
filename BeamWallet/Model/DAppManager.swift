//
//  DAppManager.swift
//  BeamWallet
//
//  Install / uninstall / list locally-installed DApps.
//

import Foundation
// SSZipArchive is exposed to Swift through the bridging header.

enum DAppManagerError: Error {
    case invalidGUID
    case missingManifestGUID
    case unzipFailed
    case bundledAssetMissing(String)
}

@objc final class DAppManager: NSObject {

    @objc static let shared = DAppManager()

    static let defaultEntry = "app/index.html"
    private let installedKey = "installed_dapps"
    private let guidRegex = try! NSRegularExpression(pattern: "^[a-fA-F0-9]{32,64}$")

    private override init() { super.init() }

    private var dappsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("dapps", isDirectory: true)
    }

    private func ensureDappsDirectory() throws {
        let dir = dappsDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Persistence

    @objc func installed() -> [BMInstalledDApp] {
        guard let raw = UserDefaults.standard.string(forKey: installedKey),
              let data = raw.data(using: .utf8),
              let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
            return []
        }
        return arr.compactMap { item in
            let dapp = BMInstalledDApp.fromDictionary(item)
            return dapp.guid.isEmpty ? nil : dapp
        }
    }

    private func saveInstalled(_ list: [BMInstalledDApp]) {
        let serialised = list.map { $0.toDictionary() }
        guard let data = try? JSONSerialization.data(withJSONObject: serialised, options: []),
              let json = String(data: data, encoding: .utf8) else { return }
        UserDefaults.standard.set(json, forKey: installedKey)
    }

    // MARK: - Validation

    private func isValidGUID(_ guid: String) -> Bool {
        let range = NSRange(guid.startIndex..<guid.endIndex, in: guid)
        return guidRegex.firstMatch(in: guid, range: range) != nil
    }

    /// Rejects path-traversal, absolute paths, and anything outside `localapp/`.
    private func validateManifestURL(_ url: String) -> String? {
        if url.isEmpty { return DAppManager.defaultEntry }
        if url.contains("..") || url.contains("//") { return nil }
        if url.hasPrefix("/") || url.hasPrefix("\\") { return nil }
        // Strip the desktop `localapp/` prefix so the load resolves directly
        // against the DApp directory.
        if url.hasPrefix("localapp/") {
            return String(url.dropFirst("localapp/".count))
        }
        if url.contains("/") && !url.hasPrefix("app/") {
            return nil
        }
        return url
    }

    // MARK: - Install

    /// Installs a `.dapp` (ZIP) and returns the resulting record. The dapps
    /// directory is keyed by the manifest's `guid` field — we don't know that
    /// value until the archive is extracted, so the unzip is staged in a temp
    /// directory and only then moved into place.
    @objc func installFromZip(data: Data,
                              fallbackName: String,
                              fallbackIcon: String) throws -> BMInstalledDApp {
        try ensureDappsDirectory()

        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("dapp-stage-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        var stagingValid = true
        defer { if stagingValid { try? FileManager.default.removeItem(at: staging) } }

        let tmpZip = FileManager.default.temporaryDirectory
            .appendingPathComponent("dapp-\(UUID().uuidString).zip")
        try data.write(to: tmpZip)
        defer { try? FileManager.default.removeItem(at: tmpZip) }

        guard SSZipArchive.unzipFile(atPath: tmpZip.path, toDestination: staging.path) else {
            throw DAppManagerError.unzipFailed
        }

        // Drop anything resembling path traversal — SSZipArchive accepts entries
        // verbatim. Walk the extracted tree and delete files that resolved
        // outside the staging directory (canonicalised paths help on iOS where
        // /private/var aliases /var).
        sanitizeExtractedTree(dir: staging)

        var manifest: [String: Any] = [:]
        let manifestPath = staging.appendingPathComponent("manifest.json")
        if let mData = try? Data(contentsOf: manifestPath),
           let parsed = (try? JSONSerialization.jsonObject(with: mData)) as? [String: Any] {
            manifest = parsed
        }

        let manifestGuid = (manifest["guid"] as? String) ?? ""
        guard !manifestGuid.isEmpty else { throw DAppManagerError.missingManifestGUID }
        guard isValidGUID(manifestGuid) else { throw DAppManagerError.invalidGUID }

        let dir = dappsDirectory.appendingPathComponent(manifestGuid, isDirectory: true)
        if FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.removeItem(at: dir)
        }
        try FileManager.default.moveItem(at: staging, to: dir)
        stagingValid = false

        let icon = DAppStore.firstIcon(in: dir) ?? fallbackIcon
        let rawURL = (manifest["url"] as? String) ?? DAppManager.defaultEntry
        let safeURL = validateManifestURL(rawURL) ?? DAppManager.defaultEntry

        let dapp = BMInstalledDApp()
        dapp.guid = manifestGuid
        dapp.name = (manifest["name"] as? String) ?? fallbackName
        dapp.desc = (manifest["description"] as? String) ?? ""
        dapp.version = (manifest["version"] as? String) ?? "1.0"
        dapp.localPath = dir.path
        dapp.icon = icon
        dapp.url = safeURL

        var list = installed()
        list.removeAll { $0.guid == manifestGuid }
        list.append(dapp)
        saveInstalled(list)

        return dapp
    }

    /// Walks the extracted DApp directory and removes any file whose canonical
    /// path escapes the root — SSZipArchive accepts traversal entries verbatim
    /// on older versions, so we sanitise after the fact.
    private func sanitizeExtractedTree(dir: URL) {
        let fm = FileManager.default
        let rootStandardized = dir.standardizedFileURL.path
        guard let enumerator = fm.enumerator(at: dir,
                                             includingPropertiesForKeys: [.isRegularFileKey],
                                             options: []) else { return }
        for case let url as URL in enumerator {
            let resolved = url.standardizedFileURL.path
            if !resolved.hasPrefix(rootStandardized) {
                try? fm.removeItem(at: url)
            }
        }
    }

    @objc func installFromBundle(assetName: String,
                                 fallbackName: String) throws -> BMInstalledDApp {
        guard let url = Bundle.main.url(forResource: (assetName as NSString).deletingPathExtension,
                                        withExtension: (assetName as NSString).pathExtension) else {
            throw DAppManagerError.bundledAssetMissing(assetName)
        }
        let data = try Data(contentsOf: url)
        return try installFromZip(data: data, fallbackName: fallbackName, fallbackIcon: "")
    }

    @objc func uninstall(guid: String) {
        let dir = dappsDirectory.appendingPathComponent(guid)
        try? FileManager.default.removeItem(at: dir)
        var list = installed()
        list.removeAll { $0.guid == guid }
        saveInstalled(list)
    }

    // MARK: - Launch

    /// Returns the file:// URL pointing at the DApp's entry HTML, clamped to
    /// stay inside the DApp directory.
    @objc func launchURL(for dapp: BMInstalledDApp) -> URL? {
        let root = URL(fileURLWithPath: dapp.localPath, isDirectory: true).standardizedFileURL
        let safeURL = validateManifestURL(dapp.url) ?? DAppManager.defaultEntry
        let target = root.appendingPathComponent(safeURL).standardizedFileURL
        if !target.path.hasPrefix(root.path) {
            return root.appendingPathComponent(DAppManager.defaultEntry)
        }
        return target
    }
}
