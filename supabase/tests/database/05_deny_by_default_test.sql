-- ============================================================================
-- F1-T01 — 05_deny_by_default_test.sql — PM-06 (deny by default)
-- ----------------------------------------------------------------------------
-- RED esperado: FALHAR porque sem RLS o acesso é aberto por padrão.
-- Usuário SEM membership em nenhuma organização não deve ver nada.
-- ============================================================================

-- @test: PM-06 usuario sem membership nao ve nada
begin;
select extensions.plan(1);
\ir setup.sql
-- Usuário do seed real (juliano) que NÃO tem membership nas fixtures
set local role authenticated;
set local request.jwt.claim.sub = '88c5c256-8f56-467e-a537-e3054769acdb';

select extensions.results_eq(
  'select count(*) from public.accounts',
  array[0::bigint],
  'PM-06: usuario sem membership nao ve nada (deny by default)'
);

rollback;