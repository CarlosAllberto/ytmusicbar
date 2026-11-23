import AppKit
import WebKit

// Toca pelo player oficial numa WKWebView escondida: resolve assinatura e PO token sozinho.
final class Player: NSObject, ObservableObject, WKScriptMessageHandler {
    static let shared = Player()  // janela e tray tocam no mesmo player
    @Published var current: Item?
    @Published var playing = false

    @Published private(set) var queue: [Item] = []
    @Published private(set) var index = 0
    @Published private(set) var position = 0.0
    @Published private(set) var duration = 0.0
    @Published var shuffle = false { didSet { applyShuffle() } }
    @Published var repeatMode = RepeatMode.off
    enum RepeatMode { case off, all, one }

    private var ordered: [Item] = []  // ordem original, para desligar o embaralhar
    private var timer: Timer?

    private let web: WKWebView
    private var host: NSWindow?
    private var rulesReady = false
    private var pending: URL?

    override init() {
        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: 400, height: 300), configuration: cfg)
        web.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        super.init()
        // 'ended' não borbulha, por isso captura. Avança a nossa fila em vez da rádio automática do site.
        let js = "document.addEventListener('ended',e=>{if(e.target.tagName==='VIDEO')webkit.messageHandlers.ended.postMessage(0)},true)"
        web.configuration.userContentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        web.configuration.userContentController.add(self, name: "ended")
        // O WebKit já publica a faixa no Now Playing do macOS com os dados do site; um MPNowPlayingInfoCenter nosso duplicava.
        // Próxima/anterior desse painel e das teclas de mídia vão para a nossa fila; play/pause de lá atualizam o estado.
        let media = """
        (()=>{const ms=navigator.mediaSession;if(!ms)return;const post=a=>()=>webkit.messageHandlers.media.postMessage(a);
        const own={nexttrack:post('next'),previoustrack:post('previous')};const set=ms.setActionHandler.bind(ms);
        ms.setActionHandler=(a,h)=>set(a,own[a]||h);for(const a in own)set(a,own[a]);
        for(const ev of['play','pause'])document.addEventListener(ev,e=>{if(e.target.tagName==='VIDEO')post(ev)()},true)})()
        """
        web.configuration.userContentController.addUserScript(WKUserScript(source: media, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        web.configuration.userContentController.add(self, name: "media")
        // Bloqueio de anúncios igual ao YTMusicBar: script que pula anúncios e regras de rede. Só carrega depois das regras.
        if let u = Bundle.main.url(forResource: "inject-ads", withExtension: "js"), let src = try? String(contentsOf: u) {
            web.configuration.userContentController.addUserScript(WKUserScript(source: src, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        AdBlock.install(in: web.configuration.userContentController) { [weak self] in
            guard let self else { return }
            self.rulesReady = true
            if let u = self.pending { self.pending = nil; self.web.load(URLRequest(url: u)) }
        }
    }

    // Fim da faixa: 'uma' repete, 'todas' volta ao começo da fila.
    // Fim da fila com "Manter ordem": esvazia a página para o site não seguir com a rádio automática.
    // Sem ela, o site segue sozinho e a interface fica mostrando a última faixa da fila.
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        if m.name == "media" {
            switch m.body as? String {
            case "next": next()
            case "previous": previous()
            case "play": playing = true
            case "pause": playing = false
            default: break
            }
            return
        }
        if repeatMode == .one, let c = current { load(c) }
        else if repeatMode == .all, index == queue.count - 1, let f = queue.first { index = 0; load(f) }
        else if index == queue.count - 1, Prefs.keepOrder { web.load(URLRequest(url: URL(string: "about:blank")!)); playing = false }
        else { next() }
    }

    func next() { step(1) }
    func previous() { step(-1) }
    private func step(_ d: Int) {
        let i = index + d
        guard queue.indices.contains(i) else { return }
        index = i
        load(queue[i])
    }

    /// Toca `t` e usa as faixas tocáveis de `list` como fila.
    func play(_ t: Item, in list: [Item] = []) {
        queue = list.filter { $0.videoId != nil }
        index = queue.firstIndex { $0.id == t.id } ?? 0
        if queue.isEmpty { queue = [t] }
        ordered = queue
        if shuffle { applyShuffle() }
        load(t)
    }

    /// Toca a faixa `i` da fila.
    func play(at i: Int) { if queue.indices.contains(i) { index = i; load(queue[i]) } }

    // Liga: embaralha o que vem depois da atual. Desliga: volta à ordem original.
    private func applyShuffle() {
        guard let c = current, !queue.isEmpty else { return }
        if shuffle { queue = [c] + queue.filter { $0.id != c.id }.shuffled() }
        else { queue = ordered }
        index = queue.firstIndex { $0.id == c.id } ?? 0
    }

    func seek(to s: Double) {
        position = s
        web.evaluateJavaScript("(()=>{const v=document.querySelector('video');if(v)v.currentTime=\(s)})()")
    }

    private func tick() {
        web.evaluateJavaScript("(()=>{const v=document.querySelector('video');return v?[v.currentTime,isFinite(v.duration)?v.duration:0]:null})()") { [weak self] r, _ in
            guard let self, let a = r as? [Double], a.count == 2 else { return }
            position = a[0]; duration = a[1]
        }
    }

    private func load(_ t: Item) {
        current = t
        if host == nil {
            // Janela fora da tela para o macOS não suspender a página. Criada só ao tocar, para não competir com a janela principal.
            let w = NSWindow(contentRect: NSRect(x: -10000, y: -10000, width: 400, height: 300), styleMask: [.borderless], backing: .buffered, defer: false)
            w.isReleasedWhenClosed = false
            // .transient esconde do Mission Control/Exposé; .ignoresCycle tira do ⌘`.
            w.collectionBehavior = [.transient, .ignoresCycle]
            w.contentView = web
            w.orderBack(nil)
            host = w
        }
        playing = true
        position = 0; duration = 0
        if timer == nil { timer = .scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() } }
        let url = URL(string: "https://music.youtube.com/watch?v=\(t.videoId ?? "")")!
        if rulesReady { web.load(URLRequest(url: url)) } else { pending = url }
    }

    func toggle() { setPlaying(nil) }

    /// nil alterna; true/false força, para teclas de play e pause não se desfazerem.
    private func setPlaying(_ on: Bool?) {
        // Parado no fim da fila (página vazia): play recomeça a última faixa.
        if on != false, web.url?.absoluteString == "about:blank", let c = current { load(c); return }
        let want = on.map(String.init) ?? "v.paused"
        web.evaluateJavaScript("(()=>{const v=document.querySelector('video');if(!v)return false;\(want)?v.play():v.pause();return !v.paused})()") { [weak self] r, _ in
            if let on = r as? Bool { self?.playing = on }
        }
    }
}
