import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKey: HotKeyService?
    private var media: MediaControls!

    func applicationDidFinishLaunching(_ notification: Notification) {
        popover.contentSize = PopoverController.size
        popover.behavior = .transient
        popover.contentViewController = PopoverController()

        media = MediaControls { js in WebViewHost.shared.run(js) }
        WebViewHost.shared.onNowPlaying = { [weak self] info in self?.media.update(info) }
        WebViewHost.shared.start()  // carrega a página já na abertura, para tocar sem popover

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "YTMusicBar")
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        applyShortcutSetting()
    }

    @objc private func statusItemClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu() } else { togglePopover() }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func applyShortcutSetting() {
        hotKey = Settings.globalShortcut ? HotKeyService { [weak self] in self?.togglePopover() } : nil
    }

    private func showMenu() {
        let menu = NSMenu()
        func add(_ title: String, _ action: Selector, on: Bool? = nil, key: String = "") {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.target = self
            if let on { item.state = on ? .on : .off }
        }
        add("Abrir", #selector(open))
        add("Recarregar", #selector(reload))
        menu.addItem(.separator())
        add("Manter ordem das faixas", #selector(toggleOrder), on: Settings.keepOrder)
        add("Atalho global (Option+S)", #selector(toggleShortcut), on: Settings.globalShortcut)
        add("Iniciar com o macOS", #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Sair", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        // Atribuir o menu só durante o clique evita que o botão passe a ignorar o left click.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func open() { if !popover.isShown { togglePopover() } }
    @objc private func reload() { WebViewHost.shared.reload() }

    @objc private func toggleOrder() {
        Settings.keepOrder.toggle()
        WebViewHost.shared.applyOrderSetting()
    }

    @objc private func toggleShortcut() {
        Settings.globalShortcut.toggle()
        applyShortcutSetting()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("YTMusicBar: falha ao alterar início com o macOS: %@", "\(error)")
        }
    }
}
