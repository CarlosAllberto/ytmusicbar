import AppKit

/// Conteúdo do popover: mostra o WebView compartilhado enquanto está aberto.
final class PopoverController: NSViewController {
    static let size = NSSize(width: 420, height: 640)

    override func loadView() {
        view = NSView(frame: NSRect(origin: .zero, size: Self.size))
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        let webView = WebViewHost.shared.webView
        webView.removeFromSuperview()
        webView.frame = view.bounds
        webView.autoresizingMask = [.width, .height]
        view.addSubview(webView)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // inject-ui.js decide a página: player se estiver tocando, senão início.
        // O blur tira o anel de foco que o WebKit mostra no último elemento focado (ex.: chip "Podcasts").
        WebViewHost.shared.run("window.__ytmOnOpen?.(); document.activeElement?.blur()")
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        // Devolve a WebView à janela oculta para o áudio seguir tocando.
        WebViewHost.shared.park()
    }
}
