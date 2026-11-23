import AppKit
import WebKit
import CryptoKit

// Login Google numa WKWebView; "logado" = cookie SAPISID no store default (o mesmo que o Player usa).
@MainActor final class Auth: NSObject, ObservableObject, WKNavigationDelegate {
    static let shared = Auth()
    @Published var loggedIn = false
    @Published var photo: URL?
    private var window: NSWindow?

    private var store: WKHTTPCookieStore { WKWebsiteDataStore.default().httpCookieStore }

    func cookies() async -> [HTTPCookie] {
        await store.allCookies().filter { $0.domain.hasSuffix("youtube.com") }
    }

    func refresh() async {
        loggedIn = await cookies().contains { $0.name == "SAPISID" || $0.name == "__Secure-3PAPISID" }
        photo = loggedIn ? await InnerTube.avatar() : nil
    }

    func logout() async {
        await WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
        await refresh()
    }

    // Cabeçalhos autenticados, ou nil se deslogado.
    func headers() async -> [String: String]? {
        let c = await cookies()
        guard let sid = (c.first { $0.name == "SAPISID" } ?? c.first { $0.name == "__Secure-3PAPISID" })?.value else { return nil }
        let ts = Int(Date().timeIntervalSince1970)
        let hash = Insecure.SHA1.hash(data: Data("\(ts) \(sid) https://music.youtube.com".utf8)).map { String(format: "%02x", $0) }.joined()
        return ["Cookie": c.map { "\($0.name)=\($0.value)" }.joined(separator: "; "),
                "Authorization": "SAPISIDHASH \(ts)_\(hash)",
                "X-Goog-AuthUser": "0", "X-Origin": "https://music.youtube.com"]
    }

    func login() {
        if let w = window { w.makeKeyAndOrderFront(nil); return }
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 480, height: 640), configuration: WKWebViewConfiguration())
        web.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        web.navigationDelegate = self
        web.load(URLRequest(url: URL(string: "https://accounts.google.com/ServiceLogin?service=youtube&continue=https://music.youtube.com")!))
        let w = NSWindow(contentRect: web.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Entrar"; w.isReleasedWhenClosed = false; w.contentView = web
        w.center(); w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w
    }

    func webView(_ w: WKWebView, didFinish _: WKNavigation!) {
        guard w.url?.host == "music.youtube.com" else { return }
        window?.close(); window = nil
        Task { await refresh() }
    }
}

private extension WKHTTPCookieStore {
    func allCookies() async -> [HTTPCookie] { await withCheckedContinuation { getAllCookies($0.resume) } }
}
