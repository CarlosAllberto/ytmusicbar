---
paths:
  - "YTMusicBar/App/**"
  - "YTMusicBar/Views/**"
---

# Interface

- Só tray: `App.swift` tem uma cena `Settings { EmptyView() }` vazia e o `TrayDelegate` (`Tray.swift`) cria `NSStatusItem` + `NSPopover` 420x640 com um `NSHostingController(ContentView)`. Clique esquerdo alterna o popover; o direito monta o `NSMenu` só durante o clique (atribuir o menu de vez faz o botão ignorar o clique esquerdo).
- Antes de mostrar o popover, `NSApp.activate(ignoringOtherApps: true)` e depois `makeKey()` na janela dele. Sem isso abre sem foco e o hover só funciona após um clique. O `activate()` novo é recusado para app de menu bar.
- O popover não acompanha o ícone quando outro item entra na barra: observadores de `didMove`/`didResize` da janela do botão reancoram `positioningRect`.
- "Recarregar" recria o `ContentView` (volta ao início e busca de novo) sem parar o `Player`.
- Liquid Glass (`glassEffect`, `safeAreaBar`) só na camada de navegação (barra de cima, voltar, mini player, botões do player) e sempre atrás de `#available(macOS 26.0, *)` com fallback; o alvo mínimo é macOS 13.
- Cursor de mão: `pointer()` e o `ButtonStyle` `Pointer` usam `pointerStyle(.link)` no macOS 15+. Antes disso, `NSCursor.pointingHand.set()` em `onContinuousHover`, reaplicado após o clique porque o re-render volta a seta.
- Busca ao digitar: debounce de 350 ms em `.task(id: query)`; `PageView(key:)` recarrega sem descartar a página atual.
- Textos da interface em português, cores em `Theme` (fundo quase preto, como o site).
