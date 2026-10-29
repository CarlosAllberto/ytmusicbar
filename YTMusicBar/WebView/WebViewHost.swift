import AppKit
import WebKit

/// Dono único do WKWebView. Quando o popover fecha, a view volta para uma janela
/// oculta, para o macOS não suspender a página e o áudio continuar tocando.
final class WebViewHost: NSObject {
    static let shared = WebViewHost()

    private static let homeURL = URL(string: "https://music.youtube.com")!
    // Safari recente: o login do Google recusa user agents que parecem embutidos.
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/27.0.1 Safari/605.1.15"

    let webView: WKWebView
    private let hiddenWindow: NSWindow

    private override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()  // mantém cookies e login entre execuções
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        let size = NSRect(origin: .zero, size: PopoverController.size)
        webView = WKWebView(frame: size, configuration: config)
        webView.customUserAgent = Self.userAgent
        #if DEBUG
        if #available(macOS 13.3, *) { webView.isInspectable = true }
        #endif

        hiddenWindow = NSWindow(contentRect: size, styleMask: .borderless, backing: .buffered, defer: false)
        hiddenWindow.isReleasedWhenClosed = false
        hiddenWindow.ignoresMouseEvents = true
        hiddenWindow.alphaValue = 0
        hiddenWindow.setFrameOrigin(NSPoint(x: -10000, y: -10000))
        hiddenWindow.collectionBehavior = [.auxiliary, .transient, .ignoresCycle]

        super.init()
        park()
        #if DEBUG
        startDebugBridge()
        #endif
    }

    #if DEBUG
    /// Só em Debug: lê tmp/ytm-eval.js, executa na página e grava tmp/ytm-eval.out. Também salva tmp/ytm.png.
    private func startDebugBridge() {
        let tmp = FileManager.default.temporaryDirectory
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let jsFile = tmp.appendingPathComponent("ytm-eval.js")
            if let js = try? String(contentsOf: jsFile) {
                try? FileManager.default.removeItem(at: jsFile)
                self.webView.callAsyncJavaScript(js, in: nil, in: .page) { result in
                    let text: String
                    switch result {
                    case .success(let v): text = "\(v ?? "nil")"
                    case .failure(let e): text = "ERRO: \(e)"
                    }
                    try? text.write(to: tmp.appendingPathComponent("ytm-eval.out"), atomically: true, encoding: .utf8)
                }
            }
            if FileManager.default.fileExists(atPath: tmp.appendingPathComponent("ytm-shot").path) {
                try? FileManager.default.removeItem(at: tmp.appendingPathComponent("ytm-shot"))
                self.webView.takeSnapshot(with: nil) { image, _ in
                    guard let tiff = image?.tiffRepresentation,
                          let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else { return }
                    try? png.write(to: tmp.appendingPathComponent("ytm.png"))
                }
            }
        }
    }
    #endif

    /// Injeta os scripts, compila as regras de bloqueio e só então carrega a página.
    func start() {
        let ucc = webView.configuration.userContentController
        // Flag lida por inject-order.js; precisa existir antes do script.
        ucc.addUserScript(WKUserScript(source: "window.__ytmOrder = { enabled: \(Settings.keepOrder) };",
                                       injectionTime: .atDocumentStart, forMainFrameOnly: true))
        if let s = Self.script("inject-ads", .atDocumentStart) { ucc.addUserScript(s) }
        if let s = Self.script("inject-order", .atDocumentEnd) { ucc.addUserScript(s) }
        if let s = Self.script("inject-ui", .atDocumentEnd) { ucc.addUserScript(s) }

        AdBlock.install(in: ucc) { [weak self] in
            self?.webView.load(URLRequest(url: Self.homeURL))
        }
    }

    private static func script(_ name: String, _ time: WKUserScriptInjectionTime) -> WKUserScript? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js"),
              let src = try? String(contentsOf: url) else {
            NSLog("YTMusicBar: %@.js não encontrado no bundle", name)
            return nil
        }
        return WKUserScript(source: src, injectionTime: time, forMainFrameOnly: true)
    }

    func park() {
        webView.removeFromSuperview()
        webView.frame = hiddenWindow.contentView?.bounds ?? webView.frame
        hiddenWindow.contentView?.addSubview(webView)
    }

    func reload() { webView.reload() }

    func run(_ js: String) { webView.evaluateJavaScript(js, completionHandler: nil) }

    func applyOrderSetting() {
        run("window.__ytmOrder && (window.__ytmOrder.enabled = \(Settings.keepOrder))")
    }
}
