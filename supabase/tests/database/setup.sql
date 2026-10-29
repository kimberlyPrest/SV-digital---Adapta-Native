-- ============================================================================
-- F1-T01/F1-T02 — setup.sql: fixtures reversíveis da suíte (SPEC-1-001)
-- ----------------------------------------------------------------------------
-- Incluído via \ir setup.sql DENTRO da transação de cada teste (termina em
-- ROLLBACK pelo runner). Nada aqui persiste. Nenhum dado real de cliente.
--
-- F1-T02: o schema real existe (migrações f1t02_*). Este setup REUTILIZA as
-- tabelas reais — sem criar shadow tables. Fixtures: 2 organizações, 5 papéis,
-- 1 usuário revogado, registros cruzados, ICP/lote/contato/auditoria.
--
-- Convenção de simulação de sessão (autorizada pelo champion em 29/09):
--   set local role authenticated;
--   set local request.jwt.claim.sub = '<uuid do usuário>';
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Fixture: usuários de teste (auth.users) — IDs FIXOS determinísticos
-- ----------------------------------------------------------------------------
insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, role, aud)
values
  ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'red.admin@svdigital.ind.br',      crypt('RedFixture#2026', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"name":"Fixture RED F1-T01"}', false, 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'red.lider@svdigital.ind.br',      crypt('RedFixture#2026', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"name":"Fixture RED F1-T01"}', false, 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'red.prospector@svdigital.ind.br', crypt('RedFixture#2026', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"name":"Fixture RED F1-T01"}', false, 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'red.vendedor@svdigital.ind.br',   crypt('RedFixture#2026', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"name":"Fixture RED F1-T01"}', false, 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'red.leitor@svdigital.ind.br',     crypt('RedFixture#2026', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"name":"Fixture RED F1-T01"}', false, 'authenticated', 'authenticated'),
  ('a0000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'red.revogado@svdigital.ind.br',   crypt('RedFixture#2026', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"name":"Fixture RED F1-T01"}', false, 'authenticated', 'authenticated')
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 2. Fixture: organizações (IDs fixos)
-- ----------------------------------------------------------------------------
insert into public.organizations (id, name)
values
  ('00000000-0000-0000-0000-0000000000a1', 'SV Org A (fixture RED)'),
  ('00000000-0000-0000-0000-0000000000b2', 'SV Org B (fixture RED)')
on conflict (id) do update set name = excluded.name;

-- ----------------------------------------------------------------------------
-- 3. Fixture: memberships (5 papéis ativos na org A + 1 revogado)
-- ----------------------------------------------------------------------------
insert into public.memberships (organization_id, user_id, role, active)
values
  ('00000000-0000-0000-0000-0000000000a1', 'a0000000-0000-0000-0000-000000000001', 'admin', true),
  ('00000000-0000-0000-0000-0000000000a1', 'a0000000-0000-0000-0000-000000000002', 'lider_comercial', true),
  ('00000000-0000-0000-0000-0000000000a1', 'a0000000-0000-0000-0000-000000000003', 'prospector', true),
  ('00000000-0000-0000-0000-0000000000a1', 'a0000000-0000-0000-0000-000000000004', 'vendedor', true),
  ('00000000-0000-0000-0000-0000000000a1', 'a0000000-0000-0000-0000-000000000005', 'leitor', true),
  ('00000000-0000-0000-0000-0000000000a1', 'a0000000-0000-0000-0000-000000000006', 'vendedor', false)
on conflict (organization_id, user_id) do update set role = excluded.role, active = excluded.active;

-- ----------------------------------------------------------------------------
-- 4. Fixture: registros cruzados (dado real da org A e da org B)
-- ----------------------------------------------------------------------------
insert into public.accounts (id, organization_id, name, cnpj, status)
values
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-0000000000a1', 'Mercado Fixture A', '00000000000191', 'ativo'),
  ('00000000-0000-0000-0000-0000000000c2', '00000000-0000-0000-0000-0000000000b2', 'Mercado Fixture B', '00000000000272', 'ativo')
on conflict (id) do update set name = excluded.name, status = excluded.status;

-- ----------------------------------------------------------------------------
-- 5. Fixture: contato com PII na org A (prova negativa do leitor/vendedor)
-- ----------------------------------------------------------------------------
insert into public.contacts (id, organization_id, name, email, phone, role)
values ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000a1', 'Contato Fixture A', 'contato@fixturea.test', '+5551999990000', 'compras')
on conflict (id) do update set email = excluded.email, phone = excluded.phone;

-- ----------------------------------------------------------------------------
-- 6. Fixture: ICP v1 publicado na org A (prova negativa PM-05/PM-04)
-- ----------------------------------------------------------------------------
insert into public.icp_versions (id, organization_id, version, name, criteria, published, approved_by)
values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000a1', 1, 'ICP Fixture RED', '{"segmento":"redes de mercados"}'::jsonb, true, 'a0000000-0000-0000-0000-000000000002')
on conflict (organization_id, version) do update set published = excluded.published;

-- ----------------------------------------------------------------------------
-- 7. Fixture: lote de importação na org A (prova negativa PM-03)
-- ----------------------------------------------------------------------------
insert into public.import_batches (id, organization_id, file_hash, imported_by)
values ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000a1', 'redfixture-hash-001', 'a0000000-0000-0000-0000-000000000003')
on conflict (organization_id, file_hash) do update set status = excluded.status;

-- ----------------------------------------------------------------------------
-- 8. Fixture: evento de auditoria pré-existente (prova M1: vendedor não lê)
-- ----------------------------------------------------------------------------
insert into public.audit_events (actor, action, object_table, object_id)
values ('a0000000-0000-0000-0000-000000000003', 'insert', 'accounts', '00000000-0000-0000-0000-0000000000c1');

-- ============================================================================
-- FIM DO SETUP — a transação permanece aberta; o runner termina com ROLLBACK.
-- ============================================================================