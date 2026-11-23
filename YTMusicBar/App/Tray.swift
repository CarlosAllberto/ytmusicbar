import AppKit
import ServiceManagement
import SwiftUI

// Ícone na barra de menus: clique abre o popover, clique direito mostra o mesmo menu do app principal.
final class TrayDelegate: NSObject, NSApplicationDelegate {
    private var item: NSStatusItem!
    private let popover = NSPopover()
    private var hotKey: HotKeyService?

    func applicationDidFinishLaunching(_ n: Notification) {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 640)
        reload()
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "YTMusicBar")
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        // Outro ícone entrando na barra (ex.: Now Playing do macOS) empurra o nosso; o popover não acompanha sozinho, então reancora.
        for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification] {
            NotificationCenter.default.addObserver(forName: name, object: item.button?.window, queue: .main) { [weak self] _ in
                guard let self, self.popover.isShown, let b = self.item.button else { return }
                self.popover.positioningRect = b.bounds
            }
        }
        // Se o YTMusicBar principal estiver aberto, ele já tem o ⌥S e o registro falha só com um log.
        hotKey = HotKeyService { [weak self] in self?.toggle() }
    }

    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu() } else { toggle() }
    }

    private func toggle() {
        guard let b = item.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Ativa antes de mostrar e torna o popover key: sem isso ele abre sem foco e o hover só funciona após um clique.
            // A ativação cooperativa (activate()) é recusada por app de menu bar; a forma antiga ainda força o foco.
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
            DispatchQueue.main.async { [weak self] in self?.popover.contentViewController?.view.window?.makeKey() }
        }
    }

    private func showMenu() {
        let m = NSMenu()
        @discardableResult
        func add(_ title: String, _ action: Selector, on: Bool? = nil, key: String = "") -> NSMenuItem {
            let i = m.addItem(withTitle: title, action: action, keyEquivalent: key)
            i.target = self
            if let on { i.state = on ? .on : .off }
            return i
        }
        add("Abrir YTMusicBar", #selector(open), key: "s").keyEquivalentModifierMask = .option  // só exibe; o atalho real é o HotKeyService
        add("Recarregar", #selector(reload))
        m.addItem(.separator())
        add("Manter ordem das faixas", #selector(toggleOrder), on: Prefs.keepOrder)
        add("Iniciar com o macOS", #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled)
        m.addItem(.separator())
        m.addItem(withTitle: "Sair", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        // Atribuir o menu só durante o clique evita que o botão passe a ignorar o left click.
        item.menu = m; item.button?.performClick(nil); item.menu = nil
    }

    @objc private func open() { if !popover.isShown { toggle() } }

    // Recria a tela do popover (volta ao início e busca tudo de novo) sem parar a música do Player.
    @objc private func reload() {
        popover.contentViewController = NSHostingController(rootView: ContentView().environmentObject(Player.shared))
    }

    @objc private func toggleOrder() { Prefs.keepOrder.toggle() }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            NSLog("YTMusicBar: falha ao alterar início com o macOS: %@", "\(error)")
        }
    }
}
