-- ============================================================================
-- F1-T02 — 07_service_role_not_exposed_test.sql — CA-1-03 / PM-01
-- ----------------------------------------------------------------------------
-- GREEN esperado: papel efetivo da sessão simulada é authenticated (nunca
-- service_role) e vendedor não lê audit_events (M1 — zero linhas).
-- ============================================================================

-- @test: PM-01 papel efetivo e M1 vendedor nao le auditoria
begin;
select extensions.plan(2);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000004';

select extensions.is(
  current_user::text,
  'authenticated',
  'PM-01: papel efetivo da sessao simulada e authenticated (nunca service_role)'
);

select extensions.results_eq(
  'select count(*) from public.audit_events',
  array[0::bigint],
  'M1: vendedor nao le audit_events (zero linhas)'
);

rollback;
