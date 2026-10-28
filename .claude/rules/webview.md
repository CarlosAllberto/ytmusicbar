---
paths:
  - "YTMusicBar/WebView/**"
  - "YTMusicBar/Views/**"
  - "YTMusicBar/App/**"
---

# WebView e popover

- AppKit, não SwiftUI: `NSStatusItem` + `NSPopover` em `App/AppDelegate.swift`. `MenuBarExtra` foi descartado (sem menu no clique direito, sem controle para manter a WebView viva). Clique esquerdo alterna o popover; o direito monta o `NSMenu` só durante o clique.
- `WebViewHost` é o dono único da `WKWebView` (singleton). Ao fechar o popover, `PopoverController` devolve a view para uma janela oculta fora da tela (`park()`), para o macOS não suspender a página e o áudio continuar. Nunca recrie a WebView.
- Ordem de inicialização: `start()` registra os `WKUserScript` e só carrega `music.youtube.com` depois que `AdBlock.install` compila as regras. Carregar antes deixa passar requisições de anúncio.
- User agent Safari fixo (`customUserAgent`), necessário para o login do Google. Sandbox ligado, só com `network.client`.
- Ao abrir o popover o WebKit mostra anel de foco no último elemento; `PopoverController.viewDidAppear` chama `blur()` para evitar.
