-- ============================================================================
-- F2-T02 / SPEC-2-001 — 10_research_test.sql
-- CA-2-01 a CA-2-04: proveniência, pesquisa necessária, contato sensível e
-- idempotência de reprocessamento.
--
-- Executa via MCP em blocos BEGIN...ROLLBACK (AP-2026-10-07-1825): o sandbox
-- não alcança a porta Postgres. Cada bloco declara plan() antes das asserções.
--
-- Status esperado no RED: erro 42P01 (tabelas research_jobs/evidences não
-- existem) e asserções de coluna ausente — é exatamente o "falham sem tabelas
-- e regras" do TDD da SPEC.
-- ============================================================================

-- @test: CA-2-01 evidência sem referência de fonte é rejeitada (RN-211)
begin;
select extensions.plan(1);
\ir setup.sql
select extensions.throws_ok(
  $q$insert into public.evidences (organization_id, account_id, field, value, source, source_ref, author)
     values ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000c1','unidades','12','brasilapi','   ','usuario:teste')$q$,
  '23514',
  NULL,
  'CA-2-01: evidência sem source_ref não é gravada'
);
rollback;

-- @test: CA-2-01 toda evidência exibe fonte, data, autor e confiança
begin;
select extensions.plan(4);
\ir setup.sql
select extensions.has_column('public','evidences','source','evidência tem fonte');
select extensions.has_column('public','evidences','collected_at','evidência tem data de coleta');
select extensions.has_column('public','evidences','author','evidência tem autor');
select extensions.has_column('public','evidences','confidence','evidência tem confiança');
rollback;

-- @test: CA-2-04 repetir a mesma evidência não duplica (RN-215)
begin;
select extensions.plan(1);
\ir setup.sql
select extensions.is(
  (select count(*)::int from (
     insert into public.evidences (organization_id, account_id, field, value, source, source_ref, author)
     values ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000c1','unidades','12','brasilapi','https://x','usuario:teste'),
            ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000c1','unidades','12','brasilapi','https://x','usuario:teste')
     on conflict (organization_id, idempotency_key) do nothing
     returning 1
   ) t),
  1,
  'CA-2-04: mesma evidência gravada duas vezes persiste uma linha'
);
rollback;

-- @test: CA-2-04 um job ativo por conta+fonte (RN-215)
begin;
select extensions.plan(1);
\ir setup.sql
select extensions.is(
  (select count(*)::int from (
     insert into public.research_jobs (organization_id, account_id, source, status)
     values ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000c1','brasilapi','fila'),
            ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-0000000000c1','brasilapi','fila')
     on conflict (account_id, source) where status in ('fila','executando') do nothing
     returning 1
   ) t),
  1,
  'CA-2-04: reprocessar reusa o job ativo'
);
rollback;

-- @test: CA-2-03 vendedor não lê evidência de contato com telefone/e-mail (M6)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000004';
select extensions.is(
  (select count(*)::int from public.evidences where contact_id is not null),
  0,
  'CA-2-03: vendedor não vê evidência de contato sensível'
);
rollback;

-- @test: CA-2-03 vendedor lê evidência de conta (M6 concede R)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000004';
select extensions.isnt(
  (select count(*)::int from public.evidences where contact_id is null),
  0,
  'CA-2-03: vendedor vê evidência de conta (não sensível)'
);
rollback;

-- @test: CA-2-02 campo obrigatório ausente leva a conta a pesquisa necessária (RN-213)
begin;
select extensions.plan(1);
\ir setup.sql
select extensions.is(
  (select research_status from public.accounts where id = '00000000-0000-0000-0000-0000000000c1'),
  'pesquisa_necessaria',
  'CA-2-02: conta sem campo obrigatório entra em pesquisa necessária'
);
rollback;

-- @test: CA-2-02 conflito de valores marca a conta (RN-212)
begin;
select extensions.plan(1);
\ir setup.sql
select extensions.is(
  (select research_status from public.accounts where id = '00000000-0000-0000-0000-0000000000c2'),
  'conflito',
  'CA-2-02: evidências divergentes marcam conflito'
);
rollback;
