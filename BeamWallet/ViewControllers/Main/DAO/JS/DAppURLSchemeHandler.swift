//
//  DAppURLSchemeHandler.swift
//  BeamWallet
//
//  Serves an installed DApp's local files to its WKWebView under a custom
//  `dapp://app/...` scheme. Native file:// loading on iOS yields status 0
//  for XHR and rejects fetch(), which silently breaks the
//  Utils.download("./*.wasm") path inside Beam DApps. Without those shader
//  bytes, the wallet's `invoke_contract` call falls through to
//  ShadersManager::nextRequest() with `m_BodyManager` empty and returns the
//  "missing shader code" error.
//

import Foundation
import WebKit

@available(iOS 11.0, *)
final class DAppURLSchemeHandler: NSObject, WKURLSchemeHandler {

    static let scheme = "dapp"
    static let host = "app"

    private let rootURL: URL
    private let rootPath: String
    private let lock = NSLock()
    private var activeTasks = Set<ObjectIdentifier>()

    init(rootURL: URL) {
        self.rootURL = rootURL.standardizedFileURL
        self.rootPath = self.rootURL.path
        super.init()
    }

    /// Builds the initial URL the WKWebView should load. `relativePath` is the
    /// manifest entry (e.g. "app/index.html").
    static func entryURL(for relativePath: String) -> URL? {
        let trimmed = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        return URL(string: "\(scheme)://\(host)/\(trimmed)")
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let id = ObjectIdentifier(urlSchemeTask)
        lock.lock(); activeTasks.insert(id); lock.unlock()

        guard let url = urlSchemeTask.request.url, url.scheme == DAppURLSchemeHandler.scheme else {
            finish(urlSchemeTask, withStatus: 400, body: nil)
            return
        }

        let relPath = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
        let target = rootURL.appendingPathComponent(relPath).standardizedFileURL

        // Path-traversal guard — refuse anything that resolves outside the
        // DApp directory after symlink/`..` normalisation.
        if target.path != rootPath && !target.path.hasPrefix(rootPath + "/") {
            finish(urlSchemeTask, withStatus: 403, body: nil)
            return
        }

        var isDir: ObjCBool = false
        let fm = FileManager.default
        var fileURL = target
        if fm.fileExists(atPath: target.path, isDirectory: &isDir), isDir.boolValue {
            fileURL = target.appendingPathComponent("index.html")
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            finish(urlSchemeTask, withStatus: 404, body: nil)
            return
        }

        let ext = fileURL.pathExtension.lowercased()
        let mime = DAppURLSchemeHandler.mimeType(for: ext)
        let bodyData: Data
        if ext == "html" || ext == "htm" {
            bodyData = injectShim(into: data)
        } else {
            bodyData = data
        }

        let headers: [String: String] = [
            "Content-Type": mime,
            "Content-Length": "\(bodyData.count)",
            "Access-Control-Allow-Origin": "*",
            "Cache-Control": "no-store",
        ]
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) else {
            finish(urlSchemeTask, withStatus: 500, body: nil)
            return
        }

        deliver(urlSchemeTask, response: response, body: bodyData)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let id = ObjectIdentifier(urlSchemeTask)
        lock.lock(); activeTasks.remove(id); lock.unlock()
    }

    // MARK: - Helpers

    private func deliver(_ task: WKURLSchemeTask, response: URLResponse, body: Data) {
        let id = ObjectIdentifier(task)
        lock.lock()
        guard activeTasks.contains(id) else { lock.unlock(); return }
        lock.unlock()
        task.didReceive(response)
        lock.lock()
        guard activeTasks.contains(id) else { lock.unlock(); return }
        lock.unlock()
        task.didReceive(body)
        lock.lock()
        activeTasks.remove(id)
        lock.unlock()
        task.didFinish()
    }

    private func finish(_ task: WKURLSchemeTask, withStatus status: Int, body: Data?) {
        guard let url = task.request.url else { return }
        let headers = ["Content-Length": "\(body?.count ?? 0)"]
        if let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers) {
            deliver(task, response: response, body: body ?? Data())
        } else {
            let id = ObjectIdentifier(task)
            lock.lock(); activeTasks.remove(id); lock.unlock()
            task.didFailWithError(NSError(domain: "DApp", code: status, userInfo: nil))
        }
    }

    private static func mimeType(for ext: String) -> String {
        switch ext {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs":   return "application/javascript; charset=utf-8"
        case "css":         return "text/css; charset=utf-8"
        case "json":        return "application/json; charset=utf-8"
        case "wasm":        return "application/wasm"
        case "svg":         return "image/svg+xml"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":         return "image/gif"
        case "webp":        return "image/webp"
        case "ico":         return "image/x-icon"
        case "woff":        return "font/woff"
        case "woff2":       return "font/woff2"
        case "ttf":         return "font/ttf"
        case "otf":         return "font/otf"
        case "eot":         return "application/vnd.ms-fontobject"
        case "map":         return "application/json; charset=utf-8"
        case "txt":         return "text/plain; charset=utf-8"
        default:            return "application/octet-stream"
        }
    }

    private func injectShim(into data: Data) -> Data {
        guard let html = String(data: data, encoding: .utf8) else { return data }
        let shim = DAppURLSchemeHandler.beamApiShim
        let lower = html.lowercased()
        let insertAt: String.Index
        if let r = lower.range(of: "<head>") {
            insertAt = r.upperBound
        } else if let r = lower.range(of: "<head ") {
            // <head ...>  — insert right after the closing '>'
            if let close = html[r.upperBound...].firstIndex(of: ">") {
                insertAt = html.index(after: close)
            } else {
                insertAt = html.startIndex
            }
        } else if let r = lower.range(of: "<html") {
            if let close = html[r.upperBound...].firstIndex(of: ">") {
                insertAt = html.index(after: close)
            } else {
                insertAt = html.startIndex
            }
        } else {
            insertAt = html.startIndex
        }
        var rewritten = html
        rewritten.insert(contentsOf: shim, at: insertAt)
        return rewritten.data(using: .utf8) ?? data
    }

    // MARK: - JS shim

    /// Injected into every HTML response:
    ///  * Forwards uncaught errors / rejections to the `dappLog` message
    ///    handler so they reach the BEAM log alongside `Call Wallet Api`.
    ///  * Tees console.error to the same channel — silent JS crashes are the
    ///    failure mode users describe as "the UI doesn't load".
    /// The XWVChannel plugin is still responsible for binding `window.BEAM`.
    static let beamApiShim: String = """
    <script>(function() {
        function send(level, message) {
            try {
                var h = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.dappLog;
                if (h) h.postMessage({ level: level, message: String(message) });
            } catch (e) {}
        }
        window.addEventListener('error', function(ev) {
            var msg = (ev && ev.message) ? ev.message : 'unknown error';
            var src = (ev && ev.filename) ? ev.filename : '?';
            var line = (ev && ev.lineno) ? ev.lineno : 0;
            send('error', '[uncaught] ' + msg + ' at ' + src + ':' + line);
        });
        window.addEventListener('unhandledrejection', function(ev) {
            var r = ev && ev.reason;
            var msg = (r && r.message) ? r.message : (r ? String(r) : 'unknown rejection');
            send('error', '[promise] ' + msg);
        });
        var origErr = console.error ? console.error.bind(console) : function() {};
        console.error = function() {
            try { send('error', Array.prototype.slice.call(arguments).map(String).join(' ')); } catch (e) {}
            try { origErr.apply(console, arguments); } catch (e) {}
        };
        var origWarn = console.warn ? console.warn.bind(console) : function() {};
        console.warn = function() {
            try { send('warn', Array.prototype.slice.call(arguments).map(String).join(' ')); } catch (e) {}
            try { origWarn.apply(console, arguments); } catch (e) {}
        };
    })();</script>
    """
}
