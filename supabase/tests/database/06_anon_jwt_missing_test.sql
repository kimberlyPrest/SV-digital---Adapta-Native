-- ============================================================================
-- F1-T01 — 06_anon_jwt_missing_test.sql — caminho de erro: JWT ausente
-- ----------------------------------------------------------------------------
-- RED esperado: FALHAR porque sem RLS o anon vê tudo.
-- Acesso anônimo (sem JWT) não deve ver nenhum registro.
-- ============================================================================

-- @test: JWT ausente anon ve zero linhas
begin;
select extensions.plan(1);
\ir setup.sql
set local role anon;

select extensions.results_eq(
  'select count(*) from public.accounts',
  array[0::bigint],
  'Caminho de erro: JWT ausente (anon) = zero linhas'
);

rollback;