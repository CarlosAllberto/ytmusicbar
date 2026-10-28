#!/usr/bin/env python3
"""Converte uma lista Adblock (EasyList) em JSON de regras do WebKit.

Uso: scripts/convert-filters.py easylist.txt > YTMusicBar/Resources/rules-easylist.json

Cobre só o básico: ||dominio^, padrões de URL simples e ##seletor genérico.
Ignora exceções (@@), opções ($...) e regras de elemento por domínio.
"""
import json
import re
import sys

LIMIT = 100000  # o WebKit aceita até 150k regras; deixa folga


def url_filter(pat: str) -> str:
    pat = pat.rstrip("^").rstrip("|").lstrip("|")
    out = re.escape(pat).replace(r"\*", ".*").replace(r"\^", "[/:?&=]")
    return out


rules = []
for line in open(sys.argv[1], encoding="utf-8", errors="ignore"):
    line = line.strip()
    if not line or line[0] in "![":
        continue
    if line.startswith("@@") or "$" in line or "#@#" in line or "#?#" in line:
        continue
    if line.startswith("##"):
        rules.append({"trigger": {"url-filter": ".*"},
                      "action": {"type": "css-display-none", "selector": line[2:]}})
    elif "##" in line:
        continue
    else:
        rules.append({"trigger": {"url-filter": url_filter(line)}, "action": {"type": "block"}})
    if len(rules) >= LIMIT:
        break

json.dump(rules, sys.stdout, indent=0)
