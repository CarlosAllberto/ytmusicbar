---
paths:
  - "YTMusicBar/Resources/*.js"
---

# Scripts injetados

Lidos do bundle por nome em `WebViewHost.script`. Todo script tem guard contra dupla execução e `try/catch`, e mantém os seletores num objeto `CONFIG` no topo, porque o DOM do YouTube muda.

- `inject-ads.js` (documentStart): MutationObserver, pula/acelera anúncio, remove promoções.
- `inject-order.js` (documentEnd): desliga shuffle, para ao fim da playlist, corrige faixa fora de ordem. Lê `window.__ytmOrder.enabled`, definido por um script prelude montado em `WebViewHost.start()` a partir de `Settings.keepOrder`.
- `inject-ui.js` (documentEnd): esconde menu hambúrguer, chips, vídeos da home e "Baixar"; carrossel de artistas inscritos (API `/youtubei/v1/browse` com SAPISIDHASH); botões do cabeçalho do artista; `window.__ytmOnOpen` (chamado ao abrir o popover: player se tocando, senão início). Navegação sem recarregar: evento `yt-navigate` no `ytmusic-app`.
- `inject-media.js` (documentEnd): envia o estado de `navigator.mediaSession` pelo handler `nowplaying`; `WebViewHost.onNowPlaying` repassa a `MediaControls`.

Não use `requestAnimationFrame` nos scripts: pausa com a janela oculta. Os seletores de ads e ordem não foram validados contra o DOM real. Se algo parar de funcionar, inspecione a página pelo Safari e ajuste o `CONFIG`.
