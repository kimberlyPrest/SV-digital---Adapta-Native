# Fase 2 — Inteligência de contas e construção de listas

## Como esta fase anda

- O agente constrói as tasks em sequência, uma por vez, sem pedir autorização nem teste entre elas. Os testes automáticos (RED → GREEN) ficam dentro de cada task e não pedem nada ao cliente.
- O teste do cliente é um por SPEC, no fim dela, pelo roteiro curto da seção "Teste do cliente" da própria SPEC. O agente não espera esse teste para construir a SPEC seguinte, porque ela depende só do que já foi construído.
- Arquivos de teste, fixtures, evidências e logs são do agente. O cliente nunca precisa abri-los nem entrar com usuário de teste.
- Antes do fim de uma SPEC, o agente só para por dado ou acesso que só a SV tem, por ação de risco em dado real ou por falha que não consegue resolver sozinho.

## Tasks

| ID | Task | Dono | SPEC | Subseção | Critério binário | Recorte da prova | Evidência esperada | Pré-condições | Pronto quando | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| F2-T01 | Alinhar permissões do Skip à matriz e entregar a tela de importação e a tela de usuários | Ethos | SPEC-2-000 | Matriz M6, emenda de 29/10 e TDD da SPEC | CA-2-13 a CA-2-15 passam | RED → GREEN | log do teste de tabela | implementação `f989db7` | `PODE` idêntico a M1–M6 e revogação efetiva | ☑ concluída 2026-10-29 — teste de tabela RED 4 divergências → GREEN 2/2; provas HTTP 5/5 com JWT real; app v0.0.6 (`a1bfbf1`) publicado; evidencias/fase-2/f2t01-green.md |
| F2-T02 | Construir a pesquisa com proveniência: testes, jobs, evidências, fila de pesquisa e telas | Ethos | SPEC-2-001 | TDD, dados e integrações | CA-2-01 a CA-2-04 passam | RED → GREEN | migrações e log dos testes | F2-T01 | pesquisa funcional em homologação com a fonte simulada e as fontes públicas | ☑ construída 2026-10-29 — migração `f2t02_pesquisa_proveniencia` + funções; Edge Function `research-account` v1; app v0.0.7 (`33fa2f7`) publicado; prova GREEN 5/5 (idempotência, conflito, proveniência); teste do cliente pendente |
| F2-T03 | Construir a pontuação explicável versionada: testes, função e telas | Ethos | SPEC-2-002 | TDD, fluxo e regras | CA-2-05 a CA-2-08 passam | RED → GREEN | migração e log dos testes | F2-T02 | notas reproduzíveis e explicadas com os pesos das fixtures | ☑ construída 2026-10-29 — migração `f2t03_pontuacao_explicavel` (`score_runs` + `score_account`); app v0.0.8 (`2044d9b`) publicado; prova CA-2-08 (mesma execução) e CA-2-07 (estado intacto); teste do cliente pendente |
| F2-T04 | Construir lista, revisão, coortes e exportação: testes e telas | Ethos | SPEC-2-003 | TDD, fluxo e regras | CA-2-09 a CA-2-11 passam | RED → GREEN | migrações, log dos testes e CSV de teste | F2-T03 | revisão e coorte funcionais em homologação | ☑ construída 2026-10-29 — migrações `f2t04_coortes_revisao` + funções (`review_account`, `add_cohort_member`, `approve_cohort`, `export_cohort_csv`); app v0.0.10 (`90f714e`) com tela `/lista`; prova 12/12 no banco; teste do cliente pendente (coorte real) |

## Testes do cliente (um por SPEC)

| SPEC | Quando | Quem | O que fazer | Aprovado quando |
|---|---|---|---|---|
| SPEC-2-000 | F2-T01 no ar | admin da SV | convidar um usuário, trocar o papel dele e revogar; abrir a importação logado como líder | os passos funcionam e o usuário revogado perde o acesso |
| SPEC-2-001 | F2-T02 no ar | prospector da SV | pesquisar 20 contas reais do ICP | 20 contas com evidência ou em pesquisa necessária; nenhum dado sem fonte aparece como verificado |
| SPEC-2-002 | F2-T03 no ar e teste da SPEC-2-001 feito | liderança da SV | passar ao agente os pesos do ICP v1 e conferir a ordem de 15 contas conhecidas | divergências registradas e aceitas, ou nova versão do ICP publicada |
| SPEC-2-003 | F2-T04 no ar e teste da SPEC-2-002 feito | champion e liderança da SV | revisar e aprovar a primeira coorte real e exportar o CSV | CA-2-12 aprovado sem bypass |
