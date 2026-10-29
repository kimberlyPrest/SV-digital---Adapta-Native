# Changelog

## 2026-10-29 (F2-T04 — lista, revisão, coortes e exportação: FASE 2 COMPLETA)

- Migração `f2t04_coortes_revisao`: `account_reviews` (motivo obrigatório), `cohorts` (rascunho/aprovada/encerrada, versão do ICP congelada), `cohort_members`, `saved_filters`; RLS M6 em todas.
- Funções `duplicate_key`, `duplicate_groups`, `review_account`, `add_cohort_member`, `approve_cohort`, `export_cohort_csv` — SECURITY DEFINER com autorização no corpo.
- **Bug real corrigido:** `duplicate_key` degenerava para `"|"` em nome acentuado (regex descartava tudo) e agrupava 9 contas distintas como duplicadas. Agora exige nome normalizado com 3+ caracteres; a base passou a ter 3 grupos reais.
- CSV com escape RFC 4180 (`csv_field`), protegendo nome com `;` e aspas. Exportação nunca entrega telefone/e-mail (M3/M6) e fica auditada.
- Prova no banco 12/12: prospector não decide (42501), decisão sem motivo rejeitada (23514), devolvida volta a pesquisa necessária, conta em outra coorte ativa bloqueada, coorte sem aprovada/duplicidade aberta não aprova, coorte aprovada congela, conta congelada não aceita nova decisão, vendedor não exporta.
- App v0.0.10 (`90f714e`) publicado com a tela `/lista` (filtros, duplicidades sinalizadas, decisão com motivo, montagem e aprovação de coorte, exportação CSV).
- **Fase 2 com as 4 tasks construídas.** Restam os testes do cliente, que dependem de dado e decisão da SV.

## 2026-10-29 (F2-T03 — pontuação explicável construída)

- Migração `f2t03_pontuacao_explicavel`: `score_runs` (imutável por conta+versão+hash das evidências) com RLS M6 — executa líder/prospector, lê os cinco papéis.
- Função `score_account`: determinística, pesos da versão do ICP, componente `sem_evidencia` separado de zero (RN-221), impedimento marca a conta (RN-222) e a nota nunca toca o estado de revisão (RN-225).
- Provado no banco: repetir com as mesmas evidências devolve a MESMA execução (CA-2-08, `total_runs=1`) e o estado da conta permanece `nao_pesquisada` (CA-2-07).
- App v0.0.8 (`2044d9b`) publicado: tela `/pontuacao` com seleção de versão do ICP, execução do recorte e explicação por componente (peso, estado, valor, contribuição).
- F2-T04 (SPEC-2-003) não iniciada nesta rodada por orçamento de execução, não por impedimento técnico.

## 2026-10-29 (F2-T02 — pesquisa com proveniência construída)

- F2-T02 construída e provada: migração `f2t02_pesquisa_proveniencia` (`research_jobs`, `evidences`, estado de pesquisa da conta, liberação de contato), funções `enqueue_research`, `record_evidence`, `finish_research_job` e `pode_pesquisar` (SECURITY DEFINER com autorização no corpo), RLS conforme M6.
- Edge Function `research-account` v1 publicada (`verify_jwt: true`): adaptador de fonte substituível, timeout 20 s, 3 tentativas, erro sanitizado; fonte contratada NÃO ligada (sem credencial da SV).
- App v0.0.7 (`33fa2f7`) publicado: tela `/pesquisa` com fila de pesquisa necessária, disparo por seleção, evidências com fonte/URL/data/autor/confiança e cadastro manual exigindo URL; `matriz-permissoes.ts` ganhou o recurso `pesquisa` (CA-2-13 2/2).
- Prova GREEN executada no banco em transação com rollback: evidência com fonte grava; repetição não duplica (RN-215); valores divergentes marcam `conflito` com as duas evidências visíveis (RN-212). Evidências em `evidencias/fase-2/f2t02-red.txt` e `f2t02-green.md`.
- **Limite conhecido:** a base importada tem 308 contas, 0 com CNPJ e 0 com site válido (a coluna `site` traz telefone/nome de contato). A pesquisa pública exige CNPJ, então o teste do cliente da SPEC-2-001 tende a mandar todas as contas para `pesquisa_necessaria` — comportamento correto (RN-211/RN-213), mas sem demonstrar enriquecimento. Falta dado da SV (CNPJs do ICP) ou fonte contratada autorizada.
- F2-T03 e F2-T04 não construídas nesta rodada.

## 2026-10-29 (F2-T01 CONCLUDED)

- 2026-10-29 · [champion] · Task F2-T01 concluída: `PODE` alinhado a M1–M6 e tela de usuários entregue — teste de tabela RED 4 divergências (a 4a, `admin.corrigir`, não estava na SPEC) → GREEN 2/2; provas HTTP com JWT real 5/5 (admin lê contatos, vendedor/leitor sem contatos, prospector 403 em add/revoke, admin revoga e `my_role`→null, auditoria 0 sem actor, admin não importa 403); app v0.0.6 (`a1bfbf1`) publicado e verificado por papel (admin sem Importar, vendedor só Contas/Painel, `/usuarios` negado a vendedor). Migração `f2t01_permissoes_e_memberships` corrigiu 3 falhas de fundação: `audit_row_change` com fallback `auth.uid()`, `revoke_member`/`add_member` com `is_org_admin()` dentro da função + EXECUTE, policies de memberships escopadas por organização. Fase 2: 1/10.

## 2026-10-29 (reorganização da Fase 2 — vinda do GitHub)

- Fase 2 reorganizada para andar sem paradas por task: os testes RED entraram na mesma task da construção (10 tasks viraram 4: F2-T01 a F2-T04) e a validação com dados reais (20 contas, calibração com 15 contas e primeira coorte) virou o teste do cliente no fim de cada SPEC.
- SPEC-2-000: decididas a tela de importação completa e a exibição dos contatos sensíveis para `admin` no detalhe da conta; a regressão por papel passou a ser automática, sem login do cliente com usuários de teste.
- SPEC-2-001: construção com fonte simulada e fontes públicas autorizadas; a fonte contratada entra quando a SV liberar a credencial.
- SPEC-2-002: construção com os pesos das fixtures; a liderança passa os pesos reais no teste da SPEC.
- AGENTS.md: ritmo de execução e teste por SPEC.
- Merge de `0188df8` sobre 33 commits locais; conflitos resolvidos com a versão do GitHub em `04_fase-atual/` e `STATUS.md` e histórico local preservado neste changelog. F2-T01 já estava concluída antes da reorganização: permanece concluída, agora como a única task da SPEC-2-000.

## 2026-10-27 (observação do pull — snapshot arquivado da Fase 1)

- `05_entregas/fase-1/fase.md` é o **snapshot congelado** do encerramento: todas as tasks aparecem com `☐`, porque o checksum (`00be19dc…`) está travado por `phase-closure-manifest.json`. Não é regressão — os resultados reais da execução (9/9) estão neste changelog e em `evidencias/fase-1/`. O arquivo não deve ser editado sem reemitir o manifesto.

## 2026-10-27 (pull do remoto — Fase 2 liberada; DÚVIDA resolvida)

- Repositório sincronizado com o GitHub (`431a9f5`, publicado em 23/10): a cópia local estava em `7adc38d` e não via a liberação da Fase 2.
- `04_fase-atual/` agora traz a **Fase 2 — Inteligência de contas e construção de listas**, com as tasks F2-T01 a F2-T10 e as SPECs 2-000 (alinhamento de permissões e matriz M6), 2-001 (pesquisa e proveniência), 2-002 (pontuação explicável) e 2-003 (coortes e aprovação).
- Fase 1 arquivada pela consultoria em `05_entregas/fase-1/` com `phase-closure-manifest.json`; implementação Skip vinculada como submódulo em `05_entregas/sv-digital-app`.
- Merge de 25 commits locais (todo o trabalho de execução da Fase 1: migrações, suítes de teste, evidências e fechamento das tasks) com os 2 commits remotos. Conflitos resolvidos em `04_fase-atual/fase.md`, `STATUS.md` e neste changelog: estrutura e estado da fase seguem o remoto; o histórico local de execução foi preservado aqui.
- Nada enviado ao GitHub (push pendente de autorização do champion).

## 2026-10-27 (DÚVIDA registrada — Fase 2 sem plano e sem SPEC liberados) — RESOLVIDA pelo pull acima

**DÚVIDA:** pedido do champion "Comece a segunda fase" não pode ser atendido neste ciclo. O repositório não continha plano da Fase 2 (`04_fase-atual/fase.md` cobria apenas a Fase 1, com as 9 tasks) nem SPEC da Fase 2 (`04_fase-atual/specs/` tinha só as SPECs 1-001 a 1-003); `handoff-manifest.json` estava marcado como `phase: 1`.

**Resolução:** a Fase 2 havia sido liberada pela consultoria em 23/10 (`431a9f5`); a cópia local estava desatualizada. Confirmado por `git fetch` e sincronizado — plano e SPECs da Fase 2 disponíveis.

## 2026-10-23

- Fase 1 encerrada com ressalvas e arquivada em `05_entregas/fase-1/` com `phase-closure-manifest.json`.
- Implementação Skip vinculada como submódulo em `05_entregas/sv-digital-app`.
- Fase 2 liberada: SPEC-2-000 (alinhamento de permissões e matriz M6), SPEC-2-001 (pesquisa e proveniência), SPEC-2-002 (pontuação explicável) e SPEC-2-003 (coortes e aprovação), com tasks F2-T01 a F2-T10.
- F2-T01 absorve as divergências de permissão da Fase 1: importação para `lider_comercial`, leitura de contatos sensíveis por `admin` e tela de usuários/memberships.
- Matriz de rastreabilidade atualizada com SPEC-2-000, CA-2-13 a CA-2-15 e renumeração das tasks da Fase 2.

## 2026-10-27 (DÚVIDA registrada — Fase 2 sem plano e sem SPEC liberados)

**DÚVIDA:** pedido do champion "Comece a segunda fase" não pode ser atendido neste ciclo. O repositório não contém plano da Fase 2 (`04_fase-atual/fase.md` cobre apenas a Fase 1, com as 9 tasks) nem SPEC da Fase 2 (`04_fase-atual/specs/` tem só as SPECs 1-001 a 1-003). `handoff-manifest.json` está marcado como `phase: 1`. O escopo definitivo descreve a Fase 2 em nível de capacidade ("Inteligência de contas e construção de listas"), mas não é SPEC e não define tasks, critérios binários nem provas — converter escopo em SPEC é atribuição da consultoria, não do executor.

**Ação:** aguardar a consultora (Kim) liberar o plano da Fase 2 (`fase.md` com a tabela de tasks) e a primeira SPEC da fase. Nada implementado; nenhuma task aberta.

## 2026-10-22 (F1-T09 CONCLUDED — demo formal por papel aprovada · FASE 1 COMPLETA)

- Champion executou a demo formal por papel (CA-1-10) e confirmou: "demo ok". 5 papéis provados na interface real (v0.0.3). Conta DEMO removida, resíduo 0, base 308/308. SPEC-1-003 completa (3/3). **Fase 1: 9/9 — COMPLETA.** Push dos commits locais pendente de autorização explícita.

## 2026-10-16 (F1-T08 CONCLUDED — teste humano aprovado)

- Teste humano confirmado pelo champion ("funcionou"). Verificação independente PASSOU: commit a5a8d87 em árvore limpa; app v0.0.3 publicada (lastPublishedRef = lastDevBuildRef = c69a50e); base 308/308 não-reconciliadas, resíduo 0; 33 políticas RLS ativas. Fase 1: 8/9 (89%). Próxima: F1-T09 (demo formal por papel — CA-1-10, dono Champion).

## 2026-10-16 (F1-T08 implementada — telas e painel no Skip, GREEN)

- F1-T08 implementada: 4 telas no app Skip (visão por papel RN-144, contas com status/origem, fila de correção RN-143 com modal validado, painel RN-141/CA-1-11) + RPC my_role (leitura do próprio papel) + correção de fundação: helpers de RLS migrados para auth.uid() (via HTTP o PostgREST não popula request.jwt.claim.sub — a matriz M1–M5 estava cega pela API; migracao f1t08_helpers_auth_uid). QA Skip ok (v0.0.3, ref c69a50e, publicada). Provas: matriz 10/10 via HTTP real com JWT por papel (CA-1-09); interface testada no browser (login fixture líder → contas 200 → painel 308/308/308/0 com cobertura/janela → correção real com validação e sucesso; efeito devolvido, resíduo 0). CA-1-10 fica para o teste humano (F1-T09 = demo formal). Aguardando teste humano.

## 2026-10-15 (CORREÇÃO de registro — F1-T07 R01 + fixtures de auth)

- Correção pós-fechamento da F1-T07, descoberta na análise da F1-T08: o app Skip JÁ ESTÁ conectado ao Supabase real (env vars presentes; login de juliano com senha do seed provado via API — access_token válido). A causa documentada para o R01 ('app sem conexão ao Supabase') estava errada: o 'Erro de autenticação' do 2º teste veio de senha errada citada no roteiro de teste. O 1º relato do champion ('entrei no sistema') era o correto. RED do roteiro completo permanece válido (R02–R07: telas ausentes). Roteiro corrigido.
- Fix: 5 fixtures f1t07.* falhavam no auth (500 'Database error querying schema') por campos de token fora do formato GoTrue — corrigido (tokens '' e phone null, formato do seed oficial); todas autenticam agora (access_token provado).
- Aprendizado capturado: AP-2026-10-15-gotrue-seed-tokens.

## 2026-10-15 (F1-T07 concluída)

- 2026-10-15 · [champion] · Task F1-T07 concluída: roteiro RED e estados da interface entregues — RED provado com app real publicado (R01 login executado 2× pelo champion com senha correta: "Erro de autenticação"; 1º relato divergente resolvido em debug com reexecução assistida; captura com toast em capturas/red-r01-login-falha.png); R02–R07 falhos por construção (app tem só 3 rotas: /, /login, *). Provas server-side da matriz 10/10 ok. Fixtures 5 papéis ativas. Verificação independente PASSOU (app publicado ref bdf5f80, fixtures 5/5, base 308 intacta, resíduo 0). Fase 1: 7/9 (78%).

## 2026-10-15 (F1-T07 implementada — roteiro RED e estados da interface)

- F1-T07 implementada: app Skip existente (id 61901) publicado em produção (https://pagina-de-login-sv-digital-51519.goskip.app, ref bdf5f80) para serviar de superfície de prova; R01 executado contra o app real — login com usuário real FALHA com "Erro de autenticação" (app sem conexão ao Supabase, auth placeholder) — RED provado com captura (evidencias/fase-1/capturas/red-r01-login-falha.png). R02–R07 especificados e falhos por construção (telas ausentes). Provas server-side da matriz por papel: 10/10 ok (spec-1-003-red-server.txt) — vendedor/leitor sem contatos, prospector não invalida lote, lider não exclui conta, admin não importa, leitor lê painel. Fixtures: 5 usuários (um por papel) criados no Auth com memberships na org SV Digital (senhas fora do git). Resíduo 0. Entregável: evidencias/fase-1/spec-1-003-roteiro-red.md (roteiro GREEN + estados + contrato para a F1-T08). Aguardando teste humano.

## 2026-10-15 (F1-T06 concluída)

- 2026-10-15 · [champion] · Task F1-T06 concluída: import real do export Kommo reconciliado e provado — lote 36c6330a (308 importados / 0 duplicados / 0 incompletos / 0 rejeitados), 244 contatos RN-123 (pesquisa_necessária), 57 fora_de_escopo, lote importado_nao_reconciliado — NADA liberado. Integridade md5 provada; idempotência (reimport → replay) e regressão RLS (não-membro: 0 leitura, 0 escrita) provadas; resíduo zero. Teste humano aprovado ("Testei e funcionou"); verificação independente PASSOU (308 contas não-reconciliadas, 244 contatos não-verificados, 1 lote, staging removida). Relatório assinado pelo champion: evidencias/fase-1/spec-1-002-reconciliacao.md (revisão da consultora na validação da fase). SPEC-1-002: 2/2 tasks concluídas — SPEC COMPLETA. Fase 1: 6/9 (67%).

## 2026-10-13 (F1-T06 implementada — import real executado)

- F1-T06 implementada: export real Kommo (308 leads) reconciliado e importado pelo caminho autorizado (authenticated + JWT do champion, papel lider_comercial — M4). Lote 36c6330a: 308 importados / 0 duplicados / 0 incompletos / 0 rejeitados; 244 contatos criados (todos RN-123: pesquisa_necessária, não-verificáveis); 57 fora_de_escopo (nunca em cadência); status do lote importado_nao_reconciliado — NADA liberado. Idempotência provada (reimport → replay, 308 mantidos); regressão RLS provada (não-membro: 0 leitura, 0 escrita); resíduo zero (staging derrubada). Relatório assinado em evidencias/fase-1/spec-1-002-reconciliacao.md. Aguardando teste humano.

## 2026-10-09 (resposta da consultora — DÚVIDA da F1-T06 resolvida)

- Consultora Kim validou os 3 pontos de mapeamento (resposta via champion, 2026-10-09 17:52):
  1. Etapas com nome de vendedor → campo **responsável**, não etapa de funil — **CONFIRMADO**;
  2. Base antiga/reativação (43 leads) → importada como **fora_de_escopo**, nunca em cadência — **CONFIRMADO**;
  3. CNPJ ausente (92%) → **reconciliar depois** (sem enriquecimento prévio; import como importado_nao_reconciliado, dedupe por título só como flag) — **CONFIRMADO**.
- Mapeamento final validado. F1-T06 destravada; aguardando autorização de implementação do champion.

## 2026-10-09 (DÚVIDA F1-T06 — aguardando consultora)

- DÚVIDA (F1-T06 — para consultora Kim, registrado pelo champion): antes do import real, validar 3 pontos de mapeamento do export Kommo (308 leads × 41 colunas, recebido 2026-10-09 — base cresceu dos 240 previstos).
  1. **Etapas legadas → taxonomia**: 17 etapas no export; 5 com nome de vendedor (Vendedor Carlos 39, Vendedora Carla 22, Vendedor Alessandro 11, Vendedor Fábio 4, DD ganho 19 = 95 leads, 31%). Proposta: virar campo responsável, NÃO etapa de funil (taxonomia controlada da F1-T05 — 7 etapas padrão). Mapeamento completo das 17 em 06_notas/mapeamento-colunas-kommo.md.
  2. **Base antiga/reativação**: Contatos SV (23) + Clientes a encaminhar (13) + Retomada de clientes antigos (7) = 43 leads que parecem base antiga/parceiros, não prospecção nova. Proposta: importadas classificadas fora_de_escopo — visíveis na base, NUNCA em cadência (escopo da máquina = novos clientes).
  3. **CNPJ ausente**: 284/308 (92%). Proposta: importar como importado_nao_reconciliado, dedupe por título apenas como flag (2 pares: fg ferramentas gerais, via atacadista), reconciliação posterior; nada liberado automaticamente (RN-16/RN-122). Alternativa em aberto: enriquecimento de CNPJ antes do import (fonte pública).
- Estado: F1-T06 bloqueada até resposta da consultora (dono: Kim, via champion). Champion pode autorizar implementação com os defaults conservadores a qualquer momento.

## 2026-10-09 (conclusão F1-T05)

- F1-T05 CONCLUDED: teste humano aprovado ("funcionou"); verificação independente PASSOU com 2 desvios corrigidos na hora (default privileges: DML a authenticated em import_batch_rows + EXECUTE via PUBLIC nas funções) — migração de hardening 20261009110000_f1t05_revoke_system_dml; re-verificado 0 DML em sistema, anon sem EXECUTE, resíduo 0. Aprendizado capturado (AP-2026-10-09-1045). Fase 1: 5/9 (56%).

## 2026-10-09

- F1-T05 (SPEC-1-002) implementada e provada GREEN: migração f1t05_model_rules_importer (funnel_stages com taxonomia controlada + seed, import_batch_rows, RN-124 imutabilidade do ICP publicado via trigger P0001, RN-121 constraint de owner/next-step/exceção, import_commercial_base idempotente por hash com RN-122/RN-123, import_batch_report com 4 categorias) + ajuste de superfície de escrita (authenticated com DML nas tabelas de negócio, RLS decide por papel; anon segue sem DML; tabelas de sistema server-side). Suíte: 10 asserções ok (evidencias/fase-1/spec-1-002-green.txt). Aguardando teste humano.

## 2026-10-08

- 2026-10-08 · [champion] · Task F1-T04 concluída: fixtures (12 contas fictícias) e suíte RED do modelo comercial provados — 5 not ok (duplicidade, imutabilidade, RN-121, relatório, importador) + 3 ok (RN-125 ×2, RN-123); teste humano aprovado.

- F1-T04 (SPEC-1-002) implementada e provada RED: fixture comercial-base.csv (12 contas fictícias — duplicatas por CNPJ, CNPJ ausente, contato sem fonte, etapas legadas) + mapeamento provisório + suíte 09_comercial_red_test.sql (5 not ok: imutabilidade ICP, importador/idempotência, RN-121, relatório; 3 ok: RN-125 ×2 e RN-123 incidental). Evidência: spec-1-002-red.txt. Aguardando teste humano.

- 2026-10-08 · [Administrador técnico] · Task F1-T03 concluída: regressão completa aprovada — 12/12 ok (revogação ponta a ponta auditada, recuperação por catálogo), inventário de secrets sem achados, função revoke_member como caminho autorizado; teste humano aprovado. SPEC-1-001 completa.

- F1-T03 (SPEC-1-001) implementada e provada: regressão completa 12/12 ok (REV-A/B/C — revogação ponta a ponta auditada, recuperação por catálogo), inventário de secrets (0 segredos, 0 achados na varredura), função revoke_member como caminho autorizado de administração. Evidências: spec-1-001-regressao.txt e secrets-inventario.md. Aguardando teste humano do Administrador técnico.

- DÚVIDA: dono da F1-T03 (Administrador técnico) sem nome definido no repositório — perguntado ao champion antes de selecionar a task; F1-T04 segue elegível (pré-condição SPEC-1-001 GREEN).

- 2026-10-08 · [champion] · Juliano Dossena (Diego) assumiu o papel de Administrador técnico; F1-T03 destravada e análise iniciada.

- 2026-10-08 · [champion] · Task F1-T02 concluída: schema base, Auth, RLS M1–M5, auditoria e filas provados GREEN — 13 asserções ok (evidencias/fase-1/spec-1-001-green.txt), 5 migrações versionadas, endurecimento de grants; teste humano aprovado pelo champion.

## 2026-10-07

- 2026-10-07 · [champion] · Task F1-T01 concluída: suíte RED de isolamento e papéis (SPEC-1-001) provada — 12 asserções RED + 1 ok sanidade (evidencias/fase-1/spec-1-001-red.txt), rollback verificado (0 tabelas/0 usuários residuais), teste humano aprovado pelo champion.
- F1-T01 (SPEC-1-001) concluída tecnicamente: suíte RED de isolamento e papéis criada e executada contra o projeto Supabase diegocunha's Project.
- Criados `supabase/tests/database/` (setup.sql com fixtures reversíveis, 7 arquivos de teste pgtap, runner.sh e runner.py) e migração de infraestrutura `test_infra_pgtap_extension` (pgtap no schema extensions).
- Execução via MCP (protocolo Postgres bloqueado no sandbox): 12 asserções RED (not ok, esperado) + 1 ok de sanidade PM-01; rollback verificado — 0 tabelas em public e 0 usuários fixture residuais.
- Evidência: `evidencias/fase-1/spec-1-001-red.txt`. Correções de execução registradas no log (IDs de fixture fixos, colisão de auditoria evitada, extensions.eq → is).
- Estado: aguardando teste humano do champion antes de concluir a task.

- F1-T02 (SPEC-1-001) implementada e provada GREEN: schema base (organizations, profiles, memberships, audit_events, integration_events, accounts, contacts, icp_versions, import_batches), RLS com matriz M1–M5 + deny by default, trigger de auditoria, fila pgmq 'jobs' privada e revoke de grants DML amplos. Suíte: 13 asserções ok (evidencias/fase-1/spec-1-001-green.txt). 5 migrações versionadas em supabase/migrations/. Aguardando teste humano.

## 2026-09-28

- Emenda às SPECs da Fase 1: criada a matriz de permissões por papel (M1–M5) na SPEC-1-001 como contrato canônico de autorização, com fatias aplicáveis nas SPEC-1-002 (RN-125) e SPEC-1-003 (RN-144).
- Novo CA-1-13: prova negativa por papel (ação proibida negada e auditada) e revogação de membership com efeito imediato.
- CA-1-09 reescrito para exigir conformidade com a matriz M1–M5 e prova server-side (ocultação no frontend não é prova suficiente).
- fase.md atualizado: critérios de F1-T02 e F1-T08 referenciam a matriz e o CA-1-13.

## 2026-09-22

- Criada a pasta do cliente com o escopo definitivo, matriz de rastreabilidade e pacote da Fase 1.
- Incluída a decisão arquitetural de Supabase como backend para suportar o agente de IA no WhatsApp.
- Publicado o repositório de entrega: https://github.com/kimberlyPrest/SV-digital---Adapta-Native
