# YTMusicBar

App de menu bar para macOS que toca o YouTube Music sem anúncios. Uso pessoal, macOS 13+.

## Como rodar

```sh
brew install xcodegen          # uma vez
xcodegen generate              # gera YTMusicBar.xcodeproj a partir do project.yml
xcodebuild -project YTMusicBar.xcodeproj -scheme YTMusicBar -configuration Release -derivedDataPath build build
open build/Build/Products/Release/YTMusicBar.app
```

Clique esquerdo no ícone abre o popover. Clique direito abre o menu: Abrir, Recarregar, ordem das faixas, atalho global (Option+S), iniciar com o macOS, Sair.

## Decisões

- **Projeto Xcode gerado por xcodegen**, igual ao dmbar. O `.xcodeproj` não é editado à mão.
- **AppKit (`NSStatusItem` + `NSPopover`) em vez de `MenuBarExtra`**. `MenuBarExtra` não permite menu no clique direito e não dá controle para manter a WebView viva fora do popover. O dmbar já usa este caminho.
- **WebView estacionada numa janela oculta** quando o popover fecha, para o macOS não suspender o áudio. A WebView nunca é recriada.
- **Configurações em `UserDefaults`** (`Services/Settings.swift`). `@AppStorage` só funciona dentro de views SwiftUI.
- **Atalho global via Carbon** (Option+S), sem dependências e sem permissão de Acessibilidade.
- Sandbox ligado, só com acesso de rede cliente.

## Onde editar

- **Seletores de anúncio**: objeto `CONFIG` no topo de `YTMusicBar/Resources/inject-ads.js`.
- **Ordem das faixas**: objeto `CONFIG` no topo de `YTMusicBar/Resources/inject-order.js`.
- **Botões de mídia (play, next, previous)**: `Services/MediaControls.swift`.

## Regras de bloqueio de rede

- `Resources/rules.json` tem hosts, paths e regras `css-display-none`.
- Todo arquivo `Resources/rules*.json` é compilado na abertura (`WebView/AdBlock.swift`).
- Para uma lista extra: `scripts/convert-filters.py easylist.txt > YTMusicBar/Resources/rules-easylist.json`, depois `xcodegen generate` e rebuild. O conversor cobre só o básico (`||dominio^`, padrões simples, `##seletor`).

## Debug

Em builds Debug a WebView é inspecionável: Safari, menu Desenvolver, nome do Mac, YTMusicBar.

## Build automático

O workflow `.github/workflows/build.yml` compila em Release a cada push na `main`, em pull requests e manualmente. O `.app` compactado fica como artefato da execução. Um push de tag `v*` (ex.: `git tag v1.0 && git push --tags`) também publica uma release com o zip.

O app é assinado ad-hoc. Ao baixar o zip, remova a quarentena: `xattr -dr com.apple.quarantine YTMusicBar.app`.

## Licença

MIT, ver `LICENSE`.
