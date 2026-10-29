# AP-2026-10-09-1045 — Default privileges do Supabase re-concedem acesso a objetos novos

**Task**: F1-T05 (SPEC-1-002) · **Momento**: verificação independente pós-teste humano

## Sinal
A migração F1-T05 revogou `EXECUTE` das funções do importador apenas de `anon` e não revogou DML de `authenticated` em `import_batch_rows` (tabela server-side). A verificação independente achou: 3 grants de DML residual a authenticated + EXECUTE via PUBLIC nas duas funções.

## Causa raiz
No Supabase, default privileges concedem DML genérico a `anon`/`authenticated` em tabelas criadas por migração e `EXECUTE` a `PUBLIC` em funções novas. Revogar só de um papel não cobre o outro caminho; `PUBLIC` é um grant separado de `anon`.

## Regra reutilizável
Toda migração que cria tabela de sistema ou função security definer termina com: (1) `revoke ... on <tabela> from authenticated, anon` se server-side; (2) `revoke execute on function ... from public, anon` + `grant execute ... to <papéis>` explícitos. Verificação independente sempre consulta `information_schema.role_table_grants` e `has_function_privilege` — não confiar só no comportamento da RLS.

## Aplicado em
`20261009110000_f1t05_revoke_system_dml.sql` (migração de hardening; re-verificado: 0 DML em sistema, anon sem EXECUTE, authenticated com EXECUTE explícito).
