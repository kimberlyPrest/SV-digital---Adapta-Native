# AP-2026-10-08-1022 — Endurecimento de grants padrão do Supabase (negação em 2 camadas)

- Status: candidato
- Escopo: projeto do cliente (SV Digital — Adapta Native)
- Task/SPEC: F1-T02 / SPEC-1-001
- Sinal: o Supabase concede INSERT/UPDATE/DELETE genéricos a anon/authenticated em toda tabela nova do schema public. Com RLS ativa o dado não vaza, mas o grant amplo é superfície desnecessária: a política passa a ser a ÚNICA barreira. Revogar o DML em migração (mantendo SELECT para o PostgREST) cria negação em DUAS camadas — grant e política — e foi verificado com 0 tabelas com DML amplo após o revoke.
- Evidência: evidencias/fase-1/spec-1-001-green.txt (seção ENDURECIMENTO; consulta role_table_grants vazia pós-revoke; re-validação da suíte GREEN após o endurecimento)
- Regra reutilizável: após criar qualquer tabela em projeto Supabase, revogar INSERT/UPDATE/DELETE de anon/authenticated em migração (SELECT permanece). RLS responde "o que o papel pode fazer"; o grant restringe a superfície antes dela.
- Quando aplicar: toda migração DDL nova neste projeto (e qualquer projeto Supabase com RLS por papel).
- Quando não aplicar: tabelas intencionalmente públicas (ex.: landing pública) — aí o grant amplo é o design.
- Confiança: alta — verificado por consulta direta ao catálogo e re-validação da suíte.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.

# AP-2026-10-08-1022b — Semântica de provas negativas em RLS (pgtap)

- Status: candidato
- Escopo: projeto do cliente (SV Digital — Adapta Native)
- Task/SPEC: F1-T02 / SPEC-1-001
- Sinal: três formas de asserção negativa, cada uma para um efeito real do RLS: (1) escrita proibida lança 42501 → throws_ok(sql, '42501', NULL, desc) — com 3 args o pgtap compara a MENSAGEM do erro, que não é o rótulo do teste, e falha sempre; (2) leitura restrita não lança nada → results_eq(count, 0); (3) UPDATE sem política FOR UPDATE não lança e não altera → asserção é efeito líquido zero (CTE returning + count), não exceção.
- Evidência: falhas observadas em execução (not ok 1-4 do primeiro lote M1-M5) e correções nos arquivos 02/03/07 da suíte; GREEN final em evidencias/fase-1/spec-1-001-green.txt
- Regra reutilizável: escolher a asserção pelo EFEITO que o RLS produz (exceção de escrita / linha invisível / UPDATE sem efeito), não por conveniência de sintaxe; throws_ok sempre com 4 args e mensagem NULL.
- Quando aplicar: qualquer suíte pgtap que prove políticas RLS.
- Quando não aplicar: versões futuras de pgtap que mudem a assinatura de throws_ok.
- Confiança: alta — cada forma exercitada com falha real antes do GREEN.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.