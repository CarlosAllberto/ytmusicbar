# AGENTS.md

App de menu bar para macOS (AppKit, macOS 13+) que toca o YouTube Music em uma WKWebView, sem anúncios. Uso pessoal. Código e comentários em português, sem travessões longos.

## Comandos

O `.xcodeproj` é gerado por xcodegen a partir do `project.yml`. Não edite o `.xcodeproj` à mão. Rode `xcodegen generate` ao adicionar ou remover arquivos (inclusive em `Resources/`) ou mudar o `project.yml`.

```sh
xcodegen generate
xcodebuild -project YTMusicBar.xcodeproj -scheme YTMusicBar -configuration Debug -derivedDataPath build build
pkill YTMusicBar; open build/Build/Products/Debug/YTMusicBar.app   # relançar após o build
```

Não há testes nem lint. O app é validado manualmente (login, áudio, anúncios, ordem, teclas de mídia). Em Debug a WebView é inspecionável pelo Safari (Desenvolver, nome do Mac, YTMusicBar).

Ponte de debug (só Debug, `WebViewHost.startDebugBridge`): grave JS em `~/Library/Containers/com.treendz.ytmusicbar/Data/tmp/ytm-eval.js` e o resultado sai em `ytm-eval.out`; `touch ytm-shot` gera `ytm.png`. A janela oculta pausa `requestAnimationFrame`, então os ícones do site podem faltar nas capturas.

## Arquitetura em uma linha

`AppDelegate` (status item + popover) mostra a `WKWebView` única do `WebViewHost`, que injeta quatro scripts JS (`Resources/inject-*.js`) e carrega regras de bloqueio (`Resources/rules*.json`); `MediaControls` liga as teclas de mídia ao player.

Detalhes por área ficam em `.claude/rules/` e carregam ao mexer nos arquivos correspondentes: `webview.md`, `js-scripts.md`, `services.md`, `adblock-rules.md`.


## Lista de tarefas

O backlog fica no Linear: workspace "Carlos Alberto", time `CAR`, projeto `YTMusicBar` (use `orca linear`, skill `orca-linear`). Toda issue deste repositório entra no projeto `YTMusicBar`, nunca solta no time, para não misturar com outros projetos. Tipo pela label (`Feature`, `Improvement`, `Bug`). Estados: Backlog = ideia, Todo = próximo, In Progress = agora, Done = feito.

O checklist da tarefa atual fica na descrição da própria issue, numa seção `## Etapas` com itens `- [ ]`. Atualize a descrição com `orca linear save-issue CAR-<n> --body-file -` (a descrição é substituída inteira: leia antes com `orca linear issue CAR-<n> --full --json` e preserve o resto).

Em tarefas com várias etapas:
- Antes de começar, crie ou ache a issue, escreva as etapas em `## Etapas` e passe a issue para In Progress.
- Marque cada item assim que terminar e acrescente o que descobrir no caminho.
- Se a conversa for resumida ou você perder o fio, releia a issue In Progress antes de continuar.
- Ao concluir, passe a issue para Done.
- Trabalho novo fora do escopo vira issue nova em Todo no projeto `YTMusicBar`, sem ser resolvido na hora.
- Nunca apague nem cancele issues sem eu pedir.
- Antes de dizer que terminou, rode build e testes e informe o resultado.

Tarefa de um passo só não precisa de checklist.

Ao terminar cada tarefa, organize o resumo em três títulos: Travado em mim, O que mudou, O que encontrei.
