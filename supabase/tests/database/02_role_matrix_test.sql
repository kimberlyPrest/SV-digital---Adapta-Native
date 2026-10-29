-- ============================================================================
-- F1-T02 — 02_role_matrix_test.sql — CA-1-13 (matriz M1–M5, prova negativa)
-- ----------------------------------------------------------------------------
-- GREEN esperado com RLS: cada tentativa PROIBIDA pela matriz é NEGADA.
-- Ações proibidas são de ESCRITA (publicar ICP, importar base, gerenciar
-- memberships) → asserção throws_ok (SQLSTATE 42501). Leituras restritas
-- (leitor sem PII de contato, vendedor sem auditoria) → zero linhas.
-- Cada teste roda dentro de transação com rollback (runner).
-- ============================================================================

-- @test: PM-05 admin nao publica ICP (escrita negada)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
select extensions.throws_ok(
  'insert into public.icp_versions (organization_id, version, name, criteria, published) values (''00000000-0000-0000-0000-0000000000a1'', 99, ''ICP Admin'', ''{}''::jsonb, true)',
  '42501',
  NULL,
  'PM-05: admin nao publica ICP (tentativa negada por RLS)'
);
rollback;

-- @test: PM-04 prospector nao publica ICP (escrita negada)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.throws_ok(
  'insert into public.icp_versions (organization_id, version, name, criteria, published) values (''00000000-0000-0000-0000-0000000000a1'', 99, ''ICP Prospector'', ''{}''::jsonb, true)',
  '42501',
  NULL,
  'PM-04: prospector nao publica ICP (tentativa negada por RLS)'
);
rollback;

-- @test: PM-03 vendedor nao importa base (escrita negada)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000004';
select extensions.throws_ok(
  'insert into public.import_batches (organization_id, file_hash) values (''00000000-0000-0000-0000-0000000000a1'', ''vendedor-hash'')',
  '42501',
  NULL,
  'PM-03: vendedor nao importa base (tentativa negada por RLS)'
);
rollback;

-- @test: PM-02 leitor nao acessa contatos com PII (leitura = zero linhas)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000005';
select extensions.results_eq(
  'select count(*) from public.contacts where organization_id = ''00000000-0000-0000-0000-0000000000a1''',
  array[0::bigint],
  'PM-02: leitor nao acessa contatos com PII (zero linhas)'
);
rollback;

-- @test: M1 lider_comercial nao gerencia memberships (UPDATE sem efeito)
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000002';
-- lider não tem política FOR UPDATE em memberships: o UPDATE não altera
-- nenhuma linha (nenhuma linha visível para UPDATE) — efeito líquido: zero.
select extensions.results_eq(
  'with u as (update public.memberships set role = ''admin'' where organization_id = ''00000000-0000-0000-0000-0000000000a1'' and user_id = ''a0000000-0000-0000-0000-000000000005''::uuid returning 1) select count(*) from u',
  array[0::bigint],
  'M1: lider_comercial nao gerencia memberships (UPDATE altera zero linhas)'
);
rollback;
