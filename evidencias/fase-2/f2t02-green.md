# F2-T02 — GREEN (SPEC-2-001) · Pesquisa com proveniência

**Data:** 2026-10-29 · **Task:** F2-T02 · **SPEC:** spec-2-001-pesquisa-e-enriquecimento.md
**Autorização:** "faça a fase inteira, até concluir todas as SPECs... Não peça autorização entre as tasks"

---

## 1. RED provado

`evidencias/fase-2/f2t02-red.txt` — consulta antes da migração:

| Objeto | Estado no RED |
|---|---|
| `research_jobs` | não existe |
| `evidences` | não existe |
| `accounts.research_status` | coluna não existe |
| `contacts.released` | coluna não existe |
| `record_evidence()` | função não existe |

## 2. Migração aplicada — `f2t02_pesquisa_proveniencia` + `f2t02_funcoes_pesquisa`

- `accounts.research_status` (`nao_pesquisada`/`pesquisada`/`pesquisa_necessaria`/`conflito`) + `research_reason` + `researched_at`.
- `contacts.released` / `released_at` (RN-214: contato sem papel, canal ou verificação não é liberado).
- `research_jobs` (fila por conta+fonte) com índice único parcial `uq_research_jobs_ativo` — RN-215.
- `evidences` com `source`, `source_ref` NOT NULL, `confidence`, `author`, `collected_at`, `job_id` e `idempotency_key` gerada (`md5(account|field|source|value)`).
- RLS conforme M6: `research_jobs` R para admin/líder/prospector, escrita só líder/prospector; `evidences` de conta R para os cinco papéis, de contato só admin/líder/prospector.
- Funções `pode_pesquisar`, `enqueue_research`, `record_evidence`, `finish_research_job` — `SECURITY DEFINER` com a checagem de autorização **dentro** do corpo.
- Edge Function `research-account` (versão 1, ACTIVE, `verify_jwt: true`): adaptador de fonte substituível, timeout 20 s, 3 tentativas, erro sanitizado.

## 3. GREEN — prova executada no banco (transação com ROLLBACK)

Sessão real da fixture `prospector`, org SV, via `record_evidence()`:

| Asserção | Esperado | Obtido | Resultado |
|---|---|---|---|
| CA-2-01 evidência com fonte é gravada | linha criada | `is not null` = true | PASS |
| CA-2-01 toda evidência tem `source_ref` não vazio | 2 de 2 | 2 | PASS |
| CA-2-04 repetir a mesma evidência não duplica (RN-215) | 1 linha para o valor 12 | 1 (a repetição não criou a 2ª) | PASS |
| CA-2-02 valores divergentes marcam a conta | `conflito` | `conflito` | PASS |
| CA-2-02 as duas evidências ficam visíveis | 2 linhas vigentes | 2 | PASS |

Observação: `ca204_linhas_unidades = 2` corresponde a **dois valores distintos** (12 da BrasilAPI e 40 do site) — a repetição do valor 12 não gerou terceira linha, que é exatamente o que a RN-215 exige.

## 4. Estrutura provada em produção

`research_jobs` e `evidences` existem; 4 policies em cada; `record_evidence`, `enqueue_research`, `pode_pesquisar`, `finish_research_job` instaladas; `accounts.research_status` presente.

## 5. App — Skip v0.0.7 (`33fa2f7`) publicado

- QA do Skip: setup, análise estática, build e integrações **verdes**; suíte do projeto não roda no template (`ran: false`).
- Publicado em https://pagina-de-login-sv-digital-51519.goskip.app — ref publicada = `33fa2f7`.
- Tela `/pesquisa`: fila de pesquisa necessária, disparo por seleção, evidências com fonte/URL/data/autor/confiança e cadastro manual exigindo URL.
- `matriz-permissoes.ts` ganhou o recurso `pesquisa` (M6) — teste de tabela `CA-2-13` 2/2.

## 6. Limite conhecido do teste do cliente (registrar antes do teste)

A base importada tem **308 contas, 0 com CNPJ e 0 com site válido**; a coluna `site` traz telefone e nome de contato (sujeira da origem Kommo). A pesquisa pela BrasilAPI exige CNPJ. Portanto, hoje, as 20 contas do teste da SPEC-2-001 irão todas para `pesquisa_necessaria` com o motivo "CNPJ ausente na base" — que é a regra correta (RN-211/RN-213), mas não demonstra enriquecimento.

Para o teste da SPEC-2-001 passar de verdade, a SV precisa entregar **CNPJs das contas do ICP** (ou autorizar uma fonte contratada). Isso é dado que só a SV tem.
