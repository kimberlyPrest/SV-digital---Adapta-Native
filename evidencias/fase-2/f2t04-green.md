# F2-T04 — GREEN (SPEC-2-003) · Revisão, coortes e exportação

**Data:** 2026-10-29 · **Task:** F2-T04 · **SPEC:** spec-2-003-coortes-e-listas.md

## 1. RED provado
`evidencias/fase-2/f2t04-red.txt` — `cohorts`, `cohort_members`, `account_reviews`, `saved_filters` e as funções não existiam.

## 2. Migrações aplicadas
- `f2t04_coortes_revisao`: `account_reviews` (decisão + motivo NOT NULL com mínimo de 3 caracteres), `cohorts` (status rascunho/aprovada/encerrada, versão do ICP, congelamento), `cohort_members`, `saved_filters`; RLS M6 em todas.
- `f2t04_funcoes_revisao_coorte`: `duplicate_key`, `duplicate_groups`, `review_account`, `add_cohort_member`, `approve_cohort`, `export_cohort_csv`.
- `f2t04_fix_chave_duplicidade`: **bug real corrigido** — nome acentuado virava string vazia no regex e a chave degenerava para `"|"`, agrupando 9 contas distintas como duplicadas. Agora exige nome normalizado com 3+ caracteres.
- `f2t04_fix_csv_escaping`: `csv_field()` com aspas RFC 4180 (campos com `;`, aspas ou quebra de linha).

## 3. GREEN — prova executada (transação com ROLLBACK)

| # | Caso | Esperado | Obtido | Resultado |
|---|---|---|---|---|
| 1 | CA-2-11 prospector tentando decidir é negado | 42501 | 42501 | PASS |
| 2 | CA-2-11 decisão sem motivo é rejeitada | 23514 | 23514 | PASS |
| 3 | CA-2-11 liderança decide (aprovada/rejeitada/devolvida) | grava | gravou | PASS |
| 4 | RN-233 devolvida volta à pesquisa necessária | `pesquisa_necessaria` | `pesquisa_necessaria` | PASS |
| 5 | CA-2-11 decisão auditada com motivo | "Aderente ao ICP" | idêntico | PASS |
| 6 | RN-232 conta em outra coorte ativa bloqueada | 23514 | 23514 | PASS |
| 7 | RN-235 coorte sem conta aprovada não aprova | 23514 | 23514 | PASS |
| 8 | RN-235 duplicidade aberta bloqueia aprovação | 23514 | 23514 | PASS |
| 9 | CA-2-12 coorte aprovada e congelada | `aprovada` + `frozen_at` | `aprovada|true` | PASS |
| 10 | CA-2-12 CSV exportado com cabeçalho | cabeçalho das 8 colunas | idêntico | PASS |
| 11 | Conta congelada não aceita nova decisão | 23514 | 23514 | PASS |
| 12 | `vendedor` não exporta CSV | 42501 | 42501 | PASS |

## 4. Deduplicação (CA-2-10)
Antes da correção: 8 grupos, um deles com 9 contas — falso positivo. Depois: **3 grupos reais** na base da SV (2 pares por nome+cidade e 1 par do fixture por CNPJ).

## 5. Nota sobre o CSV
`- Raiza Vieira` e `(Grupo Argenta)` são **duas contas distintas** na base, não uma linha quebrada. O CSV estava correto desde a primeira versão; a leitura inicial foi equívoco meu. O escape RFC 4180 foi mantido porque protege nomes com `;` e aspas, comuns em razão social.

## 6. Pendente do teste do cliente
CA-2-12 exige a **primeira coorte real** aprovada pela liderança — decisão humana, não executável pelo agente (RN-3/PM-08).
