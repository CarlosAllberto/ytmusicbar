---
paths:
  - "YTMusicBar/Resources/rules*.json"
  - "YTMusicBar/WebView/AdBlock.swift"
  - "scripts/**"
---

# Bloqueio de rede

- Todo `Resources/rules*.json` do bundle é compilado por `AdBlock.install`, um identificador por arquivo.
- Lista extra: `scripts/convert-filters.py lista.txt > YTMusicBar/Resources/rules-nome.json`, depois `xcodegen generate` e rebuild. O conversor cobre só o básico (`||dominio^`, padrões simples, `##seletor`) e limita a 100000 regras.
- Os arquivos precisam começar com `rules` no nome para serem carregados.
