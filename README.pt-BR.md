<div align="center">

# YTMusicBar

**YouTube Music na barra de menus do macOS, sem anúncios.**

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![Sem dependências](https://img.shields.io/badge/dependências-nenhuma-lightgrey)
[![Licença MIT](https://img.shields.io/badge/licença-MIT-blue)](LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/CarlosAllberto/ytmusicbar/build.yml?branch=main&label=build)](https://github.com/CarlosAllberto/ytmusicbar/actions/workflows/build.yml)

[Recursos](#recursos) • [Instalação](#instalação) • [Uso](#uso) • [Como funciona](#como-funciona) • [Personalizar](#personalizar) • [Limitações](#limitações)

<a href="README.md">English</a> • Português

</div>

O YTMusicBar é um app nativo de barra de menus que toca o [YouTube Music](https://music.youtube.com) num popover compacto. Ele bloqueia anúncios, esconde o excesso de elementos e mantém a música tocando com o popover fechado.

O app carrega o site oficial do YouTube Music em uma `WKWebView`. Seu login fica salvo entre as execuções.

<p align="center">
  <img src="docs/screenshots/home.png" alt="Início com o carrossel de artistas inscritos" width="32%">
  <img src="docs/screenshots/artist.png" alt="Página do artista com os botões Iniciar, Aleatório e Mix" width="32%">
  <img src="docs/screenshots/player.png" alt="Página do player" width="32%">
</p>

> [!NOTE]
> O YTMusicBar é um projeto independente. Não tem relação com o YouTube nem com o Google.

## Recursos

- **Sem anúncios:** regras de rede bloqueiam as requisições de anúncio e um script injetado pula e esconde o que passar.
- **Carrossel de artistas inscritos:** o início começa com os artistas que você segue, atualizado toda vez que você volta a ele.
- **Interface mais limpa:** sem menu hambúrguer, filtros de clima, prateleiras de vídeo nem o item **Baixar** nos menus das faixas. O texto não pode ser selecionado.
- **Início rápido:** páginas de artista e resultados de busca ganham o botão **Iniciar** antes de Aleatório e Mix. Inscrever-se é só um ícone de coração ou check.
- **Ordem original das faixas:** o shuffle é desligado ao iniciar uma playlist ou álbum, e a reprodução para no fim em vez de seguir para sugestões. Dá para ligar e desligar pelo menu.
- **Teclas de mídia e Now Playing:** play, pause, próxima e anterior funcionam pelo teclado, e a faixa atual aparece no Now Playing do macOS.
- **Reabertura inteligente:** o popover abre no player se estiver tocando, senão na página inicial.
- **Atalho global:** <kbd>⌥</kbd> <kbd>S</kbd> abre e fecha o popover de qualquer app.
- **Iniciar com o macOS** e **sem ícone no Dock**.

## Instalação

### Baixar o app pronto

1. Baixe o `YTMusicBar.zip` da [última release](https://github.com/CarlosAllberto/ytmusicbar/releases/latest).
2. Descompacte e mova o `YTMusicBar.app` para `/Applications`.
3. Remova a quarentena e abra o app:

```bash
xattr -dr com.apple.quarantine /Applications/YTMusicBar.app
```

As releases são geradas pelo GitHub Actions para cada tag `v*`.

> [!NOTE]
> O app tem assinatura ad-hoc e não é notarizado pela Apple, então o macOS o bloqueia até você remover a quarentena.

### Compilar do código-fonte

Requisitos:

- macOS 13 ou superior
- Xcode 15 ou superior
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
git clone https://github.com/CarlosAllberto/ytmusicbar.git
cd ytmusicbar
xcodegen generate
xcodebuild -project YTMusicBar.xcodeproj -scheme YTMusicBar -configuration Release -derivedDataPath build build
open build/Build/Products/Release/YTMusicBar.app
```

O projeto Xcode é gerado a partir do [`project.yml`](project.yml) e não vai para o repositório. Rode `xcodegen generate` de novo ao adicionar ou remover arquivos.

## Uso

| Ação | Como |
| --- | --- |
| Abrir ou fechar o popover | Clique no ícone ou tecle <kbd>⌥</kbd> <kbd>S</kbd> |
| Abrir o menu | Clique direito no ícone |
| Recarregar a página | Menu, **Recarregar** |
| Manter a ordem original das faixas | Menu, **Manter ordem das faixas** |
| Iniciar com o macOS | Menu, **Iniciar com o macOS** |
| Sair | Menu, **Sair** |

Na primeira vez, entre com sua conta Google dentro do popover.

## Como funciona

```
YTMusicBar/
├── App/        AppDelegate: ícone, popover e menu
├── Views/      Conteúdo do popover
├── WebView/    WKWebView compartilhada e carga das regras de bloqueio
├── Services/   Controles de mídia, atalho global (Carbon), configurações
└── Resources/  Scripts injetados e regras de rede
```

- **AppKit, não `MenuBarExtra`.** Um status item com popover permite menu no clique direito e controle total da WebView. É também o jeito mais simples de manter a página viva.
- **Uma WebView que fica viva.** O `WebViewHost` cria uma única `WKWebView`. Quando o popover fecha, a view vai para uma janela oculta, e o áudio continua. A página só carrega depois que as regras de bloqueio compilam.
- **Três scripts injetados** em [`Resources/`](YTMusicBar/Resources):
  - `inject-ads.js` pula anúncios e remove promoções.
  - `inject-order.js` mantém a ordem original das faixas.
  - `inject-ui.js` esconde elementos, adiciona o carrossel e os botões e decide a página na reabertura.
- **Configurações** ficam em `UserDefaults`, porque `@AppStorage` só funciona dentro de views SwiftUI.

## Personalizar

O YouTube muda a página com frequência. Cada script guarda os seletores num objeto `CONFIG` no topo do arquivo:

| O quê | Onde |
| --- | --- |
| Seletores de anúncio | `CONFIG` em `inject-ads.js` |
| Seletores da ordem das faixas | `CONFIG` em `inject-order.js` |
| Elementos escondidos, carrossel, botões | `CONFIG` em `inject-ui.js` |
| Botões de play, próxima, anterior | `Services/MediaControls.swift` |

**Regras de rede.** Todo arquivo `Resources/rules*.json` é compilado na abertura. Para adicionar uma lista no formato Adblock:

```bash
scripts/convert-filters.py easylist.txt > YTMusicBar/Resources/rules-easylist.json
xcodegen generate
```

O conversor cobre só o básico: `||dominio^`, padrões de URL simples e `##seletor`.

## Limitações

> [!NOTE]
> O bloqueio de anúncios e as mudanças de interface dependem do HTML do YouTube e podem quebrar a qualquer momento. Se algo parar de funcionar, atualize os seletores acima.

- Os seletores de anúncio, shuffle e fila não foram validados em todas as variações da página.
- A reprodução só para no fim da playlist quando o tamanho original da fila foi capturado. Playlists muito curtas ou trocas rápidas de faixa podem escapar.
- Abrir a página do player reinicia a faixa, então o app restaura a posição depois. Pode haver um pequeno salto no áudio.
- O atalho fica sempre ligado e é fixo em <kbd>⌥</kbd> <kbd>S</kbd>.
- Uma conta por vez.

## Desenvolvimento

Builds Debug incluem ferramentas para inspecionar a página:

- **Web Inspector:** inspecione a `WKWebView` pelo menu Desenvolver do Safari.
- **Ponte de debug:** grave JavaScript em `~/Library/Containers/com.treendz.ytmusicbar/Data/tmp/ytm-eval.js` e o app executa na página e grava o resultado em `ytm-eval.out`. Crie `ytm-shot` na mesma pasta para salvar uma captura em `ytm.png`.

A janela oculta pausa o `requestAnimationFrame`, então ícones do site podem faltar nas capturas. Não use `requestAnimationFrame` nos scripts injetados.
