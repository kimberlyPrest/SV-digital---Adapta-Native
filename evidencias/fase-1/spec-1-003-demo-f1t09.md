# F1-T09 — Demo formal por papel (CA-1-10) · Roteiro do Champion

**App:** https://pagina-de-login-sv-digital-51519.goskip.app
**Quem executa:** Juliano (Champion) · **Duração:** ~20 min · **Objetivo:** provar que cada papel vê e faz só o que a matriz M1–M5 permite — na tela E na API.

> Como testar 5 papéis com 1 navegador: use **uma janela anônima por papel** (Chrome: Ctrl+Shift+N). O sistema permite sessões paralelas em janelas anônimas diferentes.
> Resultado de cada passo: ✅ funcionou como esperado / ❌ diferente do esperado (anote o que apareceu).

## Os 5 logins (fixtures de teste — NÃO usar seu usuário real)

| Papel | E-mail | Senha |
|---|---|---|
| Administrador | `f1t07.admin@svdigital.ind.br` | `F1t07!Admin#2026x` |
| Líder Comercial | `f1t07.lider@svdigital.ind.br` | `F1t07!Lider#2026x` |
| Prospector | `f1t07.prospector@svdigital.ind.br` | `F1t07!Prospector#2026x` |
| Vendedor | `f1t07.vendedor@svdigital.ind.br` | `F1t07!Vendedor#2026x` |
| Leitor | `f1t07.leitor@svdigital.ind.br` | `F1t07!Leitor#2026x` |

---

## Bloco A — Líder Comercial (o seu papel) · 5 min

| # | Ação | Esperado |
|---|---|---|
| A1 | Login com o líder | Tela inicial: "Você acessa como **Líder Comercial**" + 3 cartões (Contas, Fila de correção, Painel) |
| A2 | Abrir **Contas** | Lista com **309 contas** (308 da base + 1 de demo), status "Importado · não reconciliado" em âmbar, origem "Kommo"/"Fora de escopo" |
| A3 | Buscar "DEMO" | Só a conta **"0 DEMO F1-T09 (corrija-me)"** aparece |
| A4 | Abrir **Fila de correção** → "Corrigir" na conta DEMO → **Salvar sem preencher setor** | Erro visível: "Informe o setor — campo obrigatório para reconciliar a conta." |
| A5 | Preencher Setor "Varejo" + Região "RS" → **Salvar** | Mensagem verde: 'Conta "0 DEMO F1-T09 (corrija-me)" movida para a fila de pesquisa.' — a conta some da fila |
| A6 | Abrir **Painel** | 4 cards: 309 contas · **1 aguardando reconciliação a menos** (308) · 308 sem CNPJ · 0 ativas |

## Bloco B — Vendedor · 4 min (janela anônima nova)

| # | Ação | Esperado |
|---|---|---|
| B1 | Login com o vendedor | "Você acessa como **Vendedor**" + **2 cartões apenas** (Contas, Painel) — **sem** Fila de correção |
| B2 | Abrir **Contas** | Lista aparece (vendedor lê contas), mas **sem link "Fila de correção"** no rodapé |
| B3 | Abrir **Painel** | Cards visíveis, mas **sem** "1 aguardando reconciliação" da fila (vendedor não opera correção) |
| B4 | Na URL, digitar manualmente `/correcoes` | Tela "Acesso não autorizado — Seu papel (vendedor) não tem permissão para esta tela" |

## Bloco C — Leitor · 3 min (janela anônima nova)

| # | Ação | Esperado |
|---|---|---|
| C1 | Login com o leitor | "Você acessa como **Leitor**" + 2 cartões (Contas, Painel) |
| C2 | Abrir **Contas** | Lista visível (leitor lê), sem ações de correção |
| C3 | Na URL, digitar manualmente `/correcoes` | "Acesso não autorizado — Seu papel (leitor)…" |

## Bloco D — Prospector · 4 min (janela anônima nova)

| # | Ação | Esperado |
|---|---|---|
| D1 | Login com o prospector | "Você acessa como **Prospector**" + 3 cartões (Contas, Fila de correção, Painel) |
| D2 | Abrir **Fila de correção** | Fila visível (prospector também corrige), **sem** a conta DEMO (ela já foi corrigida no bloco A) |
| D3 | Abrir **Contas**, buscar "DEMO" | A conta DEMO aparece com status **"Pesquisa necessária"** (azul) — efeito da sua correção no bloco A5 |

## Bloco E — Administrador · 4 min (janela anônima nova)

| # | Ação | Esperado |
|---|---|---|
| E1 | Login com o admin | "Você acessa como **Administrador**" + cartão **"Usuários — Gestão de acessos — disponível em fase futura"** (apagado) + Contas + Painel — **sem** Fila de correção |
| E2 | Abrir **Painel** | Cards visíveis (admin lê indicadores) |

## Prova server-side (já executada por mim — não precisa repetir)

A matriz M1–M5 foi reprovada via HTTP com JWT real de cada papel: **10/10 ok** (vendedor não insere conta; vendedor/leitor não leem contatos; leitor não altera nada; prospector não invalida lote; líder não exclui; admin não importa). Detalhes em `spec-1-003-green.md`. A demo acima prova a CAMADA DE INTERFACE (CA-1-10); a API já está provada (CA-1-09).

## Depois da demo

Me diga "demo ok" (ou o que falhou). Eu: limpo a conta DEMO (resíduo 0), atualizo evidências e concluo a F1-T09 — fechando a Fase 1 (9/9).
