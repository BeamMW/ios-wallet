//
//  OraclePriceManager.swift
//  BeamWallet
//
//  Polls the on-chain Oracle2 contract for BEAM/USD when the user has opted
//  out of the centralised price feed (Settings.isOracleEnabled). Writes the
//  median value into ExchangeManager's USD/BEAM slot using the same shape
//  WalletModel::onExchangeRates would have produced.
//

import Foundation
import UIKit

@objc final class OraclePriceManager: NSObject {

    @objc static let shared = OraclePriceManager()

    // Nephrite stablecoin's Oracle2 instance — single BEAM/USD median feed.
    static let oracleCID = "4f160f01dcc6751e61d793279b803328d5332125fe8492e93ee8f3bfe9abe13b"

    // Oracle2 returns price * 1e9; BMCurrency.value is stored as price * Rules::Coin (1e8).
    private static let oracleNormalization: Double = 1_000_000_000
    private static let beamCoin: Double = 100_000_000

    private static let refreshInterval: TimeInterval = 60

    private var shaderBytes: [Int]?
    private var refreshTimer: Timer?
    private var running = false
    private var inflight = false
    private var lastPrice: Double?
    private var didFireStatusRedraw = false

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - Lifecycle

    @objc func start() {
        guard !running else {
            fetchPriceNow()
            return
        }
        running = true
        fetchPriceNow()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: OraclePriceManager.refreshInterval,
                                            repeats: true) { [weak self] _ in
            self?.fetchPriceNow()
        }
    }

    @objc func stop() {
        running = false
        refreshTimer?.invalidate()
        refreshTimer = nil
        lastPrice = nil
        didFireStatusRedraw = false
    }

    @objc private func handleForeground() {
        if running { fetchPriceNow() }
    }

    // MARK: - Fetch

    @objc func fetchPriceNow() {
        fetch(retriesLeft: 6)
    }

    private func fetch(retriesLeft: Int) {
        guard Settings.sharedManager().isOracleEnabled else { return }
        guard !inflight else { return }
        guard let shader = loadShader() else { return }
        guard let client = AppModel.sharedManager().walletAPIClient() else {
            scheduleRetry(retriesLeft: retriesLeft)
            return
        }

        inflight = true
        let args = "role=manager,action=view_median,cid=\(OraclePriceManager.oracleCID)"
        let params: [String: Any] = [
            "args": args,
            "create_tx": false,
            "contract": shader,
        ]
        client.call(method: "invoke_contract", params: params) { [weak self] (result: [AnyHashable: Any]) in
            self?.inflight = false
            self?.apply(result: result, retriesLeft: retriesLeft)
        }
    }

    private func apply(result: [AnyHashable: Any], retriesLeft: Int) {
        guard Settings.sharedManager().isOracleEnabled else { return }
        if Self.isApiNotReady(result) {
            scheduleRetry(retriesLeft: retriesLeft)
            return
        }
        guard let price = Self.parsePrice(from: result), price > 0 else { return }
        if let last = lastPrice, last == price { return }
        writeUSD(price: price)
        lastPrice = price
    }

    private func scheduleRetry(retriesLeft: Int) {
        guard retriesLeft > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.fetch(retriesLeft: retriesLeft - 1)
        }
    }

    private static func isApiNotReady(_ result: [AnyHashable: Any]) -> Bool {
        guard let err = result["error"] as? [String: Any],
              let msg = err["message"] as? String else { return false }
        return msg.localizedCaseInsensitiveContains("not ready")
    }

    private static func parsePrice(from result: [AnyHashable: Any]) -> Double? {
        // Oracle2's view_median emits a Beam-manager string in result["output"]:
        //   {"res": ["val": <u64>,"hEnd": <height>}]}
        // — note the square brackets with key:value pairs, which is not valid
        // JSON. Extract the "val" number directly.
        if let raw = (result["val"] as? NSNumber)?.doubleValue {
            return raw / oracleNormalization
        }
        if let s = result["val"] as? String, let raw = Double(s) {
            return raw / oracleNormalization
        }
        guard let output = result["output"] as? String,
              let raw = extractVal(from: output) else {
            return nil
        }
        return raw / oracleNormalization
    }

    private static func extractVal(from output: String) -> Double? {
        let pattern = #""val"\s*:\s*([0-9]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(output.startIndex..., in: output)
        guard let match = regex.firstMatch(in: output, range: range),
              match.numberOfRanges >= 2,
              let valRange = Range(match.range(at: 1), in: output) else {
            return nil
        }
        return Double(output[valRange])
    }

    private func writeUSD(price: Double) {
        let currencies = ExchangeManager.shared().currencies

        let raw = UInt64((price * OraclePriceManager.beamCoin).rounded())
        let usd = BMCurrencyType(BMCurrencyUSD)

        var found = false
        for case let currency as BMCurrency in currencies
        where currency.type == usd && currency.name == "BEAM" && currency.assetId == 0 {
            currency.value = raw
            currency.realValue = price
            currency.code = "USD"
            currency.maximumFractionDigits = 2
            found = true
            break
        }

        if !found {
            let currency = BMCurrency()
            currency.type = usd
            currency.value = raw
            currency.realValue = price
            currency.code = "USD"
            currency.name = "BEAM"
            currency.maximumFractionDigits = 2
            currencies.add(currency)
        }

        ExchangeManager.shared().changeCurrencies()
        notifyExchangeRatesChanged()
    }

    private func notifyExchangeRatesChanged() {
        let delegates = AppModel.sharedManager().delegates.allObjects
        // BMNetworkStatusView only re-renders its "rate not received" suffix on
        // network-status callbacks. We need to nudge it once to drop the suffix
        // after the first successful oracle write, but firing it every 60s
        // makes the status bar re-debounce and flicker.
        let nudgeStatus = !didFireStatusRedraw && AppModel.sharedManager().isConnected
        for case let d as WalletModelDelegate in delegates {
            d.onExchangeRatesChange?()
            if nudgeStatus { d.onNetwotkStatusChange?(true) }
        }
        if nudgeStatus { didFireStatusRedraw = true }
    }

    // MARK: - Shader

    private func loadShader() -> [Int]? {
        if let bytes = shaderBytes { return bytes }
        guard let url = Bundle.main.url(forResource: "oracle2-app", withExtension: "wasm"),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        let bytes = data.map { Int($0) }
        shaderBytes = bytes
        return bytes
    }
}
