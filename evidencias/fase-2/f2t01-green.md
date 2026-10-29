# F2-T01 — GREEN (SPEC-2-000) · Alinhamento de permissões e gestão de usuários

**Data:** 2026-10-29 · **Task:** F2-T01 · **SPEC:** spec-2-000-alinhamento-de-permissoes.md
**Autorização:** "Autorizo implementar a F2-T01 conforme o plano e as decisões do formulário"
(importação: tela completa · contatos sensíveis: dentro da tela Contas)

---

## 1. RED provado — teste de tabela `PODE` × M1–M6

`evidencias/fase-2/f2t01-red-tabela.txt` — exit 1, **4 divergências** (a SPEC previa 3):

```
lider_comercial.usuarios: PODE=false mas matriz=R
lider_comercial.importar: PODE=false mas matriz=CU
admin.contatos:           PODE=false mas matriz=R
admin.corrigir:           PODE=false mas matriz=R   <-- não estava na SPEC
```

A quarta (`admin.corrigir`) foi encontrada na análise: M5 dá `R` ao admin na fila de correção,
mas o `PODE` booleano escondia a tela inteira.

## 2. GREEN — teste de tabela

`node --test src/hooks/__tests__/pode-matriz.test.ts`

```
✔ CA-2-13 · PODE é idêntico a M1–M6 (uma linha por papel × recurso)
✔ CA-2-13 · nenhum papel tem permissão fora da matriz
tests 2 · pass 2 · fail 0
```

## 3. Provas HTTP reais (CA-2-14 / CA-2-15)

`node --test src/hooks/__tests__/permissoes-http.test.mjs` — **5/5 pass**.
Login de verdade por fixture + chamada REST/RPC com JWT do usuário (sem GUC simulado).

| Prova | Resultado observado |
|---|---|
| admin lê contatos sensíveis | > 0 contatos |
| vendedor lê contatos | **0** (PM-02) |
| leitor lê contatos | **0** (PM-02) |
| prospector atribui papel | **403** negado |
| prospector revoga membership | **403** negado |
| admin revoga → leitor perde acesso | `my_role` passa a retornar **null** |
| admin restaura membership | volta a `leitor` (fixture sem resíduo) |
| audit_events de membership **novos** | 4 eventos, **0 sem actor** (RN-103) |
| admin importa base | **403** negado (M4/PM-05) |

## 4. Migração aplicada — `f2t01_permissoes_e_memberships`

Corrige 3 falhas estruturais encontradas na análise:

1. **`audit_row_change()`** agora usa `coalesce(claim.sub, auth.uid())`. Antes, toda escrita via
   HTTP gravava `actor = null` (12 de 565 eventos históricos). Os 6 eventos de membership sem
   actor são de 12/10 e 15/10 — anteriores à correção, preservados como registro.
2. **`revoke_member`** ganhou checagem `is_org_admin(p_org)` **dentro** da função + EXECUTE para
   `authenticated`. Antes: sem grant (a tela não funcionaria) e sem verificação de quem chama
   (dar o grant criaria porta dos fundos).
3. **Policies de `memberships`** agora escopadas por `role_in_org(organization_id)` em vez de
   `has_global_role` — impede alcance entre organizações (PM-07).

Funções novas: `is_org_admin(uuid)`, `add_member(uuid, uuid, text)`.
Todas com `revoke all from public, anon` + `grant execute to authenticated, service_role`.

## 5. Frontend (Skip) — arquivos

| Arquivo | Mudança |
|---|---|
| `src/hooks/matriz-permissoes.ts` | **novo** — matriz canônica M1–M6 extraída para módulo puro, testável sem bundler |
| `src/hooks/use-papel.tsx` | consome a matriz; reexporta tipos |
| `src/pages/Usuarios.tsx` | **novo** — listar memberships, atribuir papel, revogar (só admin opera; líder lê) |
| `src/pages/Importar.tsx` | **novo** — CSV com parser de aspas, prévia das 5 primeiras linhas, hash SHA-256 para idempotência |
| `src/pages/Contatos.tsx` | **novo** — contatos com telefone/e-mail e proveniência |
| `src/pages/Contas.tsx` | expandir conta → contatos sensíveis inline (decisão do champion) |
| `src/pages/Index.tsx` | cards por papel incluindo Importar/Usuários/Contatos; card morto "fase futura" removido |
| `src/App.tsx` | rotas `/usuarios`, `/importar`, `/contatos` |

## 6. Limitações reais desta execução (não mascaradas)

- **Build local (`vite build`) NÃO rodou**: `npm install` não completou no ambiente (faltam
  arquivos de `typescript/lib`; `node_modules/.bin` vazio) e a execução direta do vite terminou em
  `Bus error (core dumped)` por memória. **Não há prova de compilação local.**
- **Publish no Skip NÃO foi executado**: as ferramentas do conector Skip não estão disponíveis
  nesta sessão. Sem publish, o teste humano no app publicado não é possível.
- `tsc --noEmit` não é conclusivo pelo mesmo motivo (bibliotecas de tipos ausentes).

**Consequência:** CA-2-13 (teste de tabela) e CA-2-14/CA-2-15 (server-side) estão provados. A
verificação de que as telas novas renderizam e a demonstração por papel dependem do publish.

## 7. Rollback

Reverter o commit do frontend; a migração é aditiva (funções `create or replace` + policies).
`revoke_member` volta ao estado anterior com o corpo anterior, se necessário.

---

## 8. Publish e verificação na interface (2026-10-29)

**Skip v0.0.6 · ref `a1bfbf1` · publicado em produção.**

| Verificação | Resultado observado |
|---|---|
| QA do Skip (setup/static/build/integrations) | **todos ok** |
| Admin em `/` | cards: Contas, **Contatos**, **Fila de correção**, **Usuários**, Painel — **sem Importar** (M4/PM-05) |
| Admin em `/usuarios` | "6 memberships" · formulário de atribuir papel · botão Revogar por linha · captura `capturas/f2t01-usuarios-admin.png` |
| Admin atribui e-mail inexistente | erro de validação visível: "Nenhum usuário cadastrado com ... — o convite por e-mail ainda não está habilitado" |
| Vendedor em `/` | **apenas Contas e Painel** (sem Contatos, sem Fila, sem Importar, sem Usuários) |
| Vendedor em `/usuarios` (URL direta) | **"Acesso não autorizado — Seu papel (vendedor) não tem permissão"** (RN-202) |

O build local antes falhava por ambiente; **o QA do Skip compilou e publicou sem erro** — a
limitação registrada na seção 6 está resolvida pela plataforma.
