---
paths:
  - "YTMusicBar/Services/**"
---

# Serviços

- `MediaControls` liga `MPRemoteCommandCenter` a cliques nos botões do `ytmusic-player-bar` via `WebViewHost.run(js)` e preenche `MPNowPlayingInfoCenter`.
- `Settings` usa `UserDefaults`. `@AppStorage` não serve fora de views SwiftUI.
- `HotKeyService` registra Option+S via Carbon (sem dependências, sem permissão de Acessibilidade). Para mudar a tecla, altere `kVK_ANSI_S` e os textos "Option+S" no menu e no README.
