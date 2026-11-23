# AGENTS.md

App de menu bar para macOS (SwiftUI + AppKit, macOS 13+), só tray, com interface nativa para o YouTube Music e áudio numa WKWebView escondida, sem anúncios. Uso pessoal. Código e comentários em português, sem travessões longos.

## Comandos

O `.xcodeproj` é gerado por xcodegen a partir do `project.yml`. Não edite o `.xcodeproj` à mão. Rode `xcodegen generate` ao adicionar ou remover arquivos (inclusive em `Resources/`) ou mudar o `project.yml`.

```sh
xcodegen generate
xcodebuild -project YTMusicBar.xcodeproj -scheme YTMusicBar -configuration Debug -derivedDataPath build build
pkill YTMusicBar; open build/Build/Products/Debug/YTMusicBar.app   # relançar após o build
```

Não há testes nem lint. O app é validado manualmente (login, busca, áudio, anúncios, fila, letra e tradução, teclas de mídia, ⌥S). Para testar o ⌥S, feche outras instâncias do YTMusicBar: o atalho só registra em uma.

## Arquitetura em uma linha

`TrayDelegate` (`App/Tray.swift`: status item, popover 420x640, menu do clique direito, ⌥S) mostra o `ContentView` SwiftUI (`App/App.swift`, `Views/PlayerView.swift`), que lê tudo da API interna `InnerTube` (logado via `Auth`) e toca pelo `Player`, uma WKWebView escondida em `music.youtube.com/watch` com `inject-ads.js` e as regras `Resources/rules*.json` (`WebView/AdBlock.swift`).

Detalhes por área ficam em `.claude/rules/` e carregam ao mexer nos arquivos correspondentes: `interface.md`, `webview.md`, `services.md`.


## Lista de tarefas

O backlog fica no Linear: workspace "Carlos Alberto", time `CAR`, projeto `YTMusicBar` (use `orca linear`, skill `orca-linear`). Toda issue deste repositório entra no projeto `YTMusicBar`, nunca solta no time, para não misturar com outros projetos. Tipo pela label (`Feature`, `Improvement`, `Bug`). Estados: Backlog = ideia, Todo = próximo, In Progress = agora, In Review = feito por mim, falta você, Done = feito.

O checklist da tarefa atual fica na descrição da própria issue, numa seção `## Etapas` com itens `- [ ]`. Atualize a descrição com `orca linear save-issue CAR-<n> --body-file -` (a descrição é substituída inteira: leia antes com `orca linear issue CAR-<n> --full --json` e preserve o resto).

Em tarefas com várias etapas:
- Antes de começar, crie ou ache a issue, escreva as etapas em `## Etapas` e passe a issue para In Progress.
- Marque cada item assim que terminar e acrescente o que descobrir no caminho.
- Se a conversa for resumida ou você perder o fio, releia a issue In Progress antes de continuar.
- Ao terminar o código, se sobrar algo que só eu posso fazer (ver o resultado na tela, configurar um serviço externo, dar o OK, aplicar algo em produção), escreva uma seção `## Pendências suas` na descrição da issue, com itens `- [ ]` que dizem o que fazer e onde, e passe a issue para In Review. In Review é a minha fila: a issue só vai para Done depois do meu OK. Se não sobrar nada para mim (ex.: mudança interna coberta por testes), passe direto para Done. O "Travado em mim" do resumo repete essas pendências; a fonte é a issue.
- Ao concluir, passe a issue para Done.
- Trabalho novo fora do escopo vira issue nova em Todo no projeto `YTMusicBar`, sem ser resolvido na hora.
- Nunca apague nem cancele issues sem eu pedir.
- Antes de dizer que terminou, rode build e testes e informe o resultado.

Tarefa de um passo só não precisa de checklist.

Ao terminar cada tarefa, organize o resumo em três títulos: Travado em mim, O que mudou, O que encontrei.
