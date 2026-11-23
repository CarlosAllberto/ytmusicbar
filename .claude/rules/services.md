---
paths:
  - "YTMusicBar/Services/InnerTube.swift"
  - "YTMusicBar/Services/Auth.swift"
  - "YTMusicBar/Services/Translate.swift"
  - "YTMusicBar/Services/Prefs.swift"
  - "YTMusicBar/Services/HotKeyService.swift"
  - "YTMusicBar/Services/Support.swift"
---

# Serviços

- `InnerTube` chama `music.youtube.com/youtubei/v1/*` direto (browse, search, next, account_menu) com `clientName` `WEB_REMIX` e `clientVersion` fixa. Se o YouTube recusar a versão, atualize a constante no `post`. `hl`/`gl` fixos em `pt`/`BR`, e o parser compara títulos em português ("Melhor resultado").
- Busca: sem filtro só vem o card do topo, então `search` faz três chamadas em paralelo com `params` fixos (artistas, músicas, álbuns) e junta com o "Melhor resultado". Se as prateleiras sumirem, os `params` mudaram.
- Home logada segue até 3 continuations e põe "Artistas inscritos" no topo. Letra: `next` aponta para uma página `MPLYt...` com a letra numa `musicDescriptionShelfRenderer`.
- `Auth`: login Google numa `NSWindow` com `WKWebView` (UA Safari); logado = cookie `SAPISID` ou `__Secure-3PAPISID` no `WKWebsiteDataStore.default()`, o mesmo do `Player`. As chamadas da InnerTube levam os cookies à mão mais `Authorization: SAPISIDHASH`. Logout apaga todos os dados de site do store default, inclusive os do player.
- `Translate` usa o endpoint gratuito não oficial `translate.googleapis.com/translate_a/single?client=gtx` (sem chave), em blocos de ~1500 caracteres, e repete com `sl=en` quando `auto` devolve o original. Pode parar de funcionar sem aviso.
- `Prefs` usa `UserDefaults` (não se chama `Settings` para não colidir com a cena do SwiftUI). `@AppStorage` não serve fora de views.
- `HotKeyService` registra ⌥S via Carbon (sem dependências, sem permissão de Acessibilidade). Se outra instância do YTMusicBar estiver aberta, o registro falha e só gera log. Para mudar a tecla, altere `kVK_ANSI_S`, o `keyEquivalent` do item "Abrir YTMusicBar" em `Tray.swift` e o README.
