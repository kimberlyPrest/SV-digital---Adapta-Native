-- ============================================================================
-- F1-T01 — 04_revocation_test.sql — CA-1-13 (revogação de membership imediata)
-- ----------------------------------------------------------------------------
-- RED esperado: FALHAR porque não existe RLS que filtre membership inativa.
-- Usuário com membership INATIVA (revogado) não deve ver NADA da org A.
-- ============================================================================

-- @test: CA-1-13 membership revogada remove acesso imediatamente
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000006';

select extensions.results_eq(
  'select count(*) from public.accounts where organization_id = ''00000000-0000-0000-0000-0000000000a1''',
  array[0::bigint],
  'CA-1-13: membership revogada remove acesso imediatamente'
);

rollback;