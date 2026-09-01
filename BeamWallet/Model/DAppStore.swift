//
//  DAppStore.swift
//  BeamWallet
//
//  Queries the on-chain DApp Store contract for published DApps and publishers,
//  caches the publisher list, downloads DApp ZIPs over IPFS via the wallet RPC.
//

import Foundation

@objc final class DAppStore: NSObject {

    @objc static let shared = DAppStore()

    static let storeCID = "e2d24b686e8d31a0fe97eade9cd23281e7059b74b5757bdb96c820ef9e2af41c"
    static let iconCandidates = ["app/icon.svg", "app/appicon.svg", "app/logo.svg"]
    private let ipfsTimeoutMS = 180_000
    private let unwantedPublishersKey = "unwanted_publishers"

    private let bundled: [BMAvailableDApp] = {
        let core = BMAvailableDApp()
        core.guid = "abcc470e12c6422291f360f83d79355e"
        core.name = "BeamX DAO"
        core.desc = "Governance, staking and voting"
        core.version = "1.0.0"
        core.bundledAsset = "dao-core-app.dapp"

        let voting = BMAvailableDApp()
        voting.guid = "c26538f5ce9e410b89c1fd0dff783f97"
        voting.name = "BeamX DAO Voting"
        voting.desc = "Voting on Beam community proposals"
        voting.version = "1.0.0"
        voting.bundledAsset = "dao-voting-app.dapp"

        return [core, voting]
    }()

    private var shaderBytes: [Int]?
    private var cachedPublishers: [BMPublisher] = []

    // MARK: - Shader

    private func loadShader() -> [Int]? {
        if let bytes = shaderBytes { return bytes }
        guard let url = Bundle.main.url(forResource: "dapps_store_app", withExtension: "wasm"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        let bytes = data.map { Int($0) }
        shaderBytes = bytes
        return bytes
    }

    // MARK: - Available DApps

    @objc func queryAvailableDApps(filterUnwanted: Bool = true,
                                   completion: @escaping ([BMAvailableDApp]) -> Void) {
        guard let shader = loadShader() else {
            completion(bundledWithIcons())
            return
        }
        loadPublishers(shader: shader) { [weak self] in
            self?.loadDApps(shader: shader, filterUnwanted: filterUnwanted, completion: completion)
        }
    }

    @objc func queryPublishers(completion: @escaping ([BMPublisher]) -> Void) {
        if !cachedPublishers.isEmpty {
            completion(cachedPublishers)
            return
        }
        guard let shader = loadShader() else {
            completion([])
            return
        }
        loadPublishers(shader: shader) { [weak self] in
            completion(self?.cachedPublishers ?? [])
        }
    }

    private func loadPublishers(shader: [Int], onDone: @escaping () -> Void) {
        if !cachedPublishers.isEmpty { onDone(); return }
        guard let client = AppModel.sharedManager().walletAPIClient() else {
            onDone()
            return
        }
        let args = "action=view_publishers,cid=\(DAppStore.storeCID)"
        let params: [String: Any] = [
            "args": args,
            "create_tx": false,
            "contract": shader,
        ]
        client.call(method: "invoke_contract", params: params) { [weak self] (result: [AnyHashable: Any]) in
            guard let self = self else { onDone(); return }
            if let publishers = result["publishers"] as? [[String: Any]] {
                self.cachedPublishers = publishers.compactMap { p in
                    guard let pubkey = p["pubkey"] as? String else { return nil }
                    let name = Self.hexToString(p["name"] as? String ?? "")
                    if name.isEmpty { return nil }
                    let pub = BMPublisher()
                    pub.pubkey = pubkey
                    pub.name = name
                    pub.aboutMe = Self.hexToString(p["about_me"] as? String ?? "")
                    pub.website = Self.hexToString(p["website"] as? String ?? "")
                    pub.twitter = Self.hexToString(p["twitter"] as? String ?? "")
                    pub.linkedin = Self.hexToString(p["linkedin"] as? String ?? "")
                    pub.instagram = Self.hexToString(p["instagram"] as? String ?? "")
                    pub.telegram = Self.hexToString(p["telegram"] as? String ?? "")
                    pub.discord = Self.hexToString(p["discord"] as? String ?? "")
                    return pub
                }
            }
            onDone()
        }
    }

    private func loadDApps(shader: [Int],
                           filterUnwanted: Bool,
                           completion: @escaping ([BMAvailableDApp]) -> Void) {
        guard let client = AppModel.sharedManager().walletAPIClient() else {
            completion(bundledWithIcons())
            return
        }
        let args = "action=view_dapps,cid=\(DAppStore.storeCID)"
        let params: [String: Any] = [
            "args": args,
            "create_tx": false,
            "contract": shader,
        ]
        client.call(method: "invoke_contract", params: params) { [weak self] (result: [AnyHashable: Any]) in
            guard let self = self else { return }
            if result["error"] != nil {
                completion(self.bundledWithIcons())
                return
            }
            guard let raw = result["dapps"] as? [[String: Any]] else {
                completion(self.bundledWithIcons())
                return
            }
            let unwanted = filterUnwanted ? self.getUnwantedPublishers() : Set<String>()
            let publisherNames: [String: String] = Dictionary(
                self.cachedPublishers.map { ($0.pubkey.lowercased(), $0.name) },
                uniquingKeysWith: { first, _ in first }
            )
            let parsed: [BMAvailableDApp] = raw.compactMap { item in
                guard let guid = item["id"] as? String else { return nil }
                let name = Self.hexToString(item["name"] as? String ?? "")
                if name.isEmpty { return nil }
                let publisherPk = (item["publisher"] as? String) ?? ""
                if !publisherPk.isEmpty && unwanted.contains(publisherPk.lowercased()) {
                    return nil
                }

                let dapp = BMAvailableDApp()
                dapp.guid = guid
                dapp.name = name
                dapp.desc = Self.hexToString(item["description"] as? String ?? "")
                dapp.ipfsCid = (item["ipfs_id"] as? String) ?? ""
                dapp.publisher = publisherPk
                dapp.publisherName = publisherNames[publisherPk.lowercased()] ?? ""

                if let ver = item["version"] as? [String: Any] {
                    let major = (ver["major"] as? NSNumber)?.intValue ?? 1
                    let minor = (ver["minor"] as? NSNumber)?.intValue ?? 0
                    let release = (ver["release"] as? NSNumber)?.intValue ?? 0
                    dapp.version = "\(major).\(minor).\(release)"
                } else {
                    dapp.version = "1.0.0"
                }

                let iconHex = (item["icon"] as? String) ?? ""
                if !iconHex.isEmpty {
                    let decoded = Self.hexToString(iconHex).trimmingCharacters(in: .whitespacesAndNewlines)
                    let prefix = "data:image/svg+xml;utf8,"
                    let svg = decoded.hasPrefix(prefix) ? String(decoded.dropFirst(prefix.count)) : decoded
                    if svg.hasPrefix("<svg") || svg.hasPrefix("<?xml") {
                        dapp.icon = svg
                    }
                }
                return dapp
            }

            let bundledWithIcons = self.bundledWithIcons()
            let bundledByGuid: [String: BMAvailableDApp] =
                Dictionary(uniqueKeysWithValues: bundledWithIcons.map { ($0.guid, $0) })
            for d in parsed where d.bundledAsset.isEmpty {
                if let b = bundledByGuid[d.guid] {
                    d.bundledAsset = b.bundledAsset
                    if d.icon.isEmpty { d.icon = b.icon }
                }
            }
            let onChainGuids = Set(parsed.map { $0.guid })
            let bundledOnly = bundledWithIcons.filter { !onChainGuids.contains($0.guid) }
            completion(bundledOnly + parsed)
        }
    }

    // MARK: - Bundled icons

    // bundled holds a per-launch cache of BMAvailableDApp instances; mutating
    // their icon field here ensures the unzip in extractIcon runs at most once.
    private func bundledWithIcons() -> [BMAvailableDApp] {
        for template in bundled where template.icon.isEmpty && !template.bundledAsset.isEmpty {
            template.icon = extractIcon(fromBundledAsset: template.bundledAsset)
        }
        return bundled
    }

    private func extractIcon(fromBundledAsset assetName: String) -> String {
        let nameNS = assetName as NSString
        guard let url = Bundle.main.url(forResource: nameNS.deletingPathExtension,
                                        withExtension: nameNS.pathExtension) else { return "" }
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("bundled-icon-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: workDir) }
        try? FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        guard SSZipArchive.unzipFile(atPath: url.path, toDestination: workDir.path) else { return "" }
        return DAppStore.firstIcon(in: workDir) ?? ""
    }

    static func firstIcon(in dir: URL) -> String? {
        for name in iconCandidates {
            let p = dir.appendingPathComponent(name)
            guard let svg = try? String(contentsOf: p, encoding: .utf8) else { continue }
            let trimmed = svg.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("<svg") || trimmed.hasPrefix("<?xml") {
                return svg
            }
        }
        return nil
    }

    // MARK: - IPFS

    @objc func downloadFromIpfs(cid: String, completion: @escaping (Data?, String?) -> Void) {
        guard let client = AppModel.sharedManager().walletAPIClient() else {
            completion(nil, "Wallet API not ready")
            return
        }
        let params: [String: Any] = ["hash": cid, "timeout": ipfsTimeoutMS]
        client.call(method: "ipfs_get", params: params) { (result: [AnyHashable: Any]) in
            if let err = result["error"] {
                let message: String
                if let dict = err as? [String: Any], let m = dict["message"] as? String { message = m }
                else if let s = err as? String { message = s }
                else { message = "IPFS download failed" }
                completion(nil, message)
                return
            }
            guard let bytes = result["data"] as? [NSNumber] else {
                completion(nil, "No data returned from IPFS")
                return
            }
            var buffer = Data(count: bytes.count)
            buffer.withUnsafeMutableBytes { raw in
                guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                for (i, num) in bytes.enumerated() {
                    base[i] = UInt8(truncatingIfNeeded: num.intValue)
                }
            }
            completion(buffer, nil)
        }
    }

    // MARK: - Version comparison

    private static func parseVersion(_ v: String) -> [Int] {
        return v.split(separator: ".").compactMap { Int($0) }
    }

    @objc static func isVersionOlder(_ a: String, than b: String) -> Bool {
        let av = parseVersion(a)
        let bv = parseVersion(b)
        let maxLen = max(av.count, bv.count)
        for i in 0..<maxLen {
            let lhs = i < av.count ? av[i] : 0
            let rhs = i < bv.count ? bv[i] : 0
            if lhs != rhs { return lhs < rhs }
        }
        return false
    }

    /// Checks the on-chain version for `dapp` and reinstalls if newer.
    /// `completion` runs on the caller's queue; `updated` is true when a fresh install ran.
    @objc func checkAndUpdate(_ dapp: BMInstalledDApp,
                              completion: @escaping (_ updated: Bool) -> Void) {
        queryAvailableDApps { [weak self] available in
            guard let self = self,
                  let match = available.first(where: { $0.guid == dapp.guid }),
                  DAppStore.isVersionOlder(dapp.version, than: match.version) else {
                completion(false)
                return
            }
            self.install(match) { installed, _ in completion(installed != nil) }
        }
    }

    // MARK: - Install dispatch

    /// Installs an available DApp from either its bundled asset or via IPFS.
    @objc func install(_ available: BMAvailableDApp,
                       completion: @escaping (BMInstalledDApp?, String?) -> Void) {
        if !available.bundledAsset.isEmpty {
            do {
                let installed = try DAppManager.shared.installFromBundle(assetName: available.bundledAsset,
                                                                        fallbackName: available.name)
                completion(installed, nil)
            } catch {
                completion(nil, "\(error)")
            }
            return
        }
        if available.ipfsCid.isEmpty {
            completion(nil, "No download source")
            return
        }
        downloadFromIpfs(cid: available.ipfsCid) { data, err in
            guard let data = data else {
                completion(nil, err ?? "Download failed")
                return
            }
            do {
                let installed = try DAppManager.shared.installFromZip(data: data,
                                                                     fallbackName: available.name,
                                                                     fallbackIcon: available.icon)
                completion(installed, nil)
            } catch {
                completion(nil, "\(error)")
            }
        }
    }

    // MARK: - Unwanted publishers

    @objc func getUnwantedPublishers() -> Set<String> {
        let arr = UserDefaults.standard.stringArray(forKey: unwantedPublishersKey) ?? []
        return Set(arr.map { $0.lowercased() })
    }

    @objc func addUnwantedPublisher(_ pubkey: String) {
        var set = getUnwantedPublishers()
        set.insert(pubkey.lowercased())
        UserDefaults.standard.set(Array(set), forKey: unwantedPublishersKey)
    }

    @objc func removeUnwantedPublisher(_ pubkey: String) {
        var set = getUnwantedPublishers()
        set.remove(pubkey.lowercased())
        UserDefaults.standard.set(Array(set), forKey: unwantedPublishersKey)
    }

    // MARK: - Hex decode

    private static func hexToString(_ hex: String) -> String {
        if hex.isEmpty { return "" }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(hex.count / 2)
        var idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if next == idx { break }
            let pair = hex[idx..<next]
            guard let byte = UInt8(pair, radix: 16) else { return "" }
            bytes.append(byte)
            idx = next
        }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
}
