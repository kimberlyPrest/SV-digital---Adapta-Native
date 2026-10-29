-- ============================================================================
-- F1-T01 — 01_isolation_test.sql — CA-1-01 (isolamento entre organizações)
-- ----------------------------------------------------------------------------
-- RED esperado: FALHAR hoje porque não existe RLS.
-- Cada teste roda dentro de transação com rollback (runner).
-- Marcadores -- @test: delimitam blocos para o runner.
-- ============================================================================

-- @test: CA-1-01 usuario da org A nao ve contas da org B
begin;
select extensions.plan(2);

-- fixture
\ir setup.sql

-- simula usuário da org A (prospector)
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';

-- 1) contagem de contas da org B deve ser ZERO
select extensions.results_eq(
  'select count(*) from public.accounts where organization_id = ''00000000-0000-0000-0000-0000000000b2''',
  array[0::bigint],
  'CA-1-01: usuario da org A nao ve contas da org B'
);

-- 2) caminho de erro obrigatório: UUID específico da org B = zero linhas
select extensions.results_eq(
  'select count(*) from public.accounts where id = ''00000000-0000-0000-0000-0000000000c2''',
  array[0::bigint],
  'Caminho de erro: UUID de outra organizacao = zero linhas'
);

rollback;