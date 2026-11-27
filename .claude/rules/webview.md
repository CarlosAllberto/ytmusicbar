---
paths:
  - "YTMusicBar/Services/Player.swift"
  - "YTMusicBar/WebView/**"
  - "YTMusicBar/Resources/*.js"
  - "YTMusicBar/Resources/rules*.json"
  - "scripts/**"
---

# Player escondido e bloqueio de anúncios

- O áudio sai de uma `WKWebView` escondida em `Player` (singleton `Player.shared`) que carrega `music.youtube.com/watch?v=ID`. O site resolve assinatura e PO token sozinho; a interface nativa nunca mostra essa WebView.
- A janela que hospeda a WebView fica fora da tela (`-10000, -10000`) e só é criada no primeiro `load`. Sem janela o macOS suspende a página e o áudio para. Nunca recrie a WebView. Ela também é transparente (`alphaValue = 0`) e ignora cliques, porque o macOS a traz para a tela ao trocar de monitor ou acordar.
- `rulesReady`: a URL só carrega depois que `AdBlock.install` compila as regras; antes disso fica em `pending`. Carregar antes deixa passar requisições de anúncio.
- A fila é nossa, não do site: um script captura o evento `ended` do `<video>` e chama `next()`. No fim da fila com `Prefs.keepOrder`, carrega `about:blank` para o site não seguir com a rádio automática; play nesse estado recarrega a última faixa.
- Posição e duração vêm de um `Timer` de 1 s que lê o `<video>` por `evaluateJavaScript`. Play/pause e seek também mexem direto no `<video>`, não nos botões do site.
- Now Playing e teclas de mídia: quem publica é o próprio WebKit, com os metadados do site. Não use `MPNowPlayingInfoCenter`/`MPRemoteCommandCenter`: aparece um segundo item no painel de mídia. Um script troca os handlers `nexttrack`/`previoustrack` do `navigator.mediaSession` pela nossa fila (mensagem `media`) e os eventos play/pause do `<video>` atualizam `playing`.
- User agent Safari fixo (`customUserAgent`), igual ao da janela de login. Sandbox ligado, só com `network.client`.

## inject-ads.js

Único script injetado (documentStart, só no frame principal). Guard `window.__ytmAds` contra dupla execução, seletores no objeto `CONFIG` do topo, porque o DOM do YouTube muda. Pula/acelera o anúncio e remove promoções. Não use `requestAnimationFrame`: pausa com a janela oculta.

## Regras de rede

- Todo `Resources/rules*.json` do bundle é compilado por `AdBlock.install`, um identificador por arquivo. O nome precisa começar com `rules`.
- Lista extra: `scripts/convert-filters.py lista.txt > YTMusicBar/Resources/rules-nome.json`, depois `xcodegen generate` e rebuild. O conversor cobre só o básico (`||dominio^`, padrões simples, `##seletor`) e limita a 100000 regras.
