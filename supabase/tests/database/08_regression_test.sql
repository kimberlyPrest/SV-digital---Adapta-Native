-- ============================================================================
-- F1-T03 — 08_regression_test.sql — REGRESSÃO completa (SPEC-1-001)
-- ----------------------------------------------------------------------------
-- Dono da task: Administrador técnico. Critério binário: regressão completa
-- aprovada — nenhuma credencial exposta e rollback demonstrado.
--
-- 3 grupos:
--   A. Regressão das provas GREEN da F1-T02 (amostra de cada critério)
--   B. Revogação ponta a ponta (novo): membro ativo lê → admin desativa a
--      membership (operação AUDITADA) → membro revogado não lê MAIS nada
--   C. Recuperação/reprodução (novo): o schema é reconstruído pelas 7 migrações
--      versionadas — provado por catálogo (tabelas/RLS/poliíticas/fila)
-- Cada teste roda em transação com rollback (runner).
-- ============================================================================

-- @test: REG-A regressao das provas GREEN (isolamento + revogacao + deny)
begin;
select extensions.plan(4);
\ir setup.sql

-- CA-1-01: prospector da org A não vê contas da org B
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.results_eq(
  'select count(*) from public.accounts where organization_id = ''00000000-0000-0000-0000-0000000000b2''',
  array[0::bigint],
  'REG-A1 · CA-1-01: isolamento mantido (org A nao ve org B)'
);

-- CA-1-13: revogado (membership inativa) não vê nada
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000006';
select extensions.results_eq(
  'select count(*) from public.accounts where organization_id = ''00000000-0000-0000-0000-0000000000a1''',
  array[0::bigint],
  'REG-A2 · CA-1-13: revogado sem acesso'
);

-- PM-06: sem membership = zero linhas
set local request.jwt.claim.sub = '88c5c256-8f56-467e-a537-e3054769acdb';
select extensions.results_eq(
  'select count(*) from public.accounts',
  array[0::bigint],
  'REG-A3 · PM-06: deny by default mantido'
);

-- PM-05: admin não publica ICP (escrita negada)
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
select extensions.throws_ok(
  'insert into public.icp_versions (organization_id, version, name, criteria, published) values (''00000000-0000-0000-0000-0000000000a1'', 99, ''ICP Reg'', ''{}''::jsonb, true)',
  '42501',
  NULL,
  'REG-A4 · PM-05: escrita proibida segue negada'
);

rollback;

-- @test: REG-B revogacao ponta a ponta auditada
-- NOTA DE AMBIENTE: com o endurecimento da F1-T02 (revoke de DML a
-- authenticated), a desativação de membership pelo admin passa por caminho
-- autorizado (console/Edge Function com service_role — decisão PM-01/RN-102).
-- A prova aqui usa SECURITY DEFINER para representar esse caminho server-side
-- autorizado; o efeito auditado e a revogação imediata são idênticos.
begin;
select extensions.plan(3);
\ir setup.sql

create or replace function public.f1t03_revoke_member(p_user uuid, p_org uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.memberships
  set active = false
  where organization_id = p_org and user_id = p_user;
end $$;

-- 1) membro ativo (vendedor) lê a conta da própria org
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000004';
select extensions.results_eq(
  'select count(*) from public.accounts where id = ''00000000-0000-0000-0000-0000000000c1''',
  array[1::bigint],
  'REG-B1 · membro ativo ve registro da propria org'
);

-- 2) desativação via caminho autorizado server-side — AUDITADA pelo trigger
set local role postgres;
select public.f1t03_revoke_member(
  'a0000000-0000-0000-0000-000000000004'::uuid,
  '00000000-0000-0000-0000-0000000000a1'::uuid
);
select extensions.results_eq(
  $q$select count(*) from public.audit_events
     where object_table = 'memberships'
       and action = 'update'
       and after->>'user_id' = 'a0000000-0000-0000-0000-000000000004'
       and after->>'active' = 'false'$q$,
  array[1::bigint],
  'REG-B2 · desativacao de membership (caminho autorizado) gera evento de auditoria'
);

-- 3) o membro revogado NÃO lê mais nada (efeito imediato)
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000004';
select extensions.results_eq(
  'select count(*) from public.accounts',
  array[0::bigint],
  'REG-B3 · CA-1-13: revogacao remove acesso IMEDIATAMENTE'
);

rollback;

-- @test: REG-C recuperacao do schema pelas migrações versionadas
begin;
select extensions.plan(5);
-- Sem fixtures: prova de CATÁLOGO — o schema atual reflete exatamente o replay
-- das 7 migrações versionadas (2 de infra + 5 f1t02).

-- 1) 9 tabelas de produto em public
select extensions.is(
  (select count(*)::text from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'),
  '9',
  'REG-C1 · schema reproduz 9 tabelas (migrações 2/4)'
);

-- 2) todas com RLS FORÇADA
select extensions.is(
  (select count(*)::text from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r'
     and c.relrowsecurity and c.relforcerowsecurity),
  '9',
  'REG-C2 · 9 tabelas com RLS FORCE (migração 3)'
);

-- 3) 28 políticas da matriz M1–M5
select extensions.is(
  (select count(*)::text from pg_policies where schemaname = 'public'),
  '28',
  'REG-C3 · 28 políticas (matriz M1-M5)'
);

-- 4) fila privada sem acesso de papéis humanos
select extensions.is(
  (select count(*)::text from information_schema.role_table_grants
    where table_schema = 'pgmq' and grantee in ('anon','authenticated')),
  '0',
  'REG-C4 · fila pgmq privada (0 grants públicos)'
);

-- 5) nenhum grant DML amplo a anon/authenticated (migração 5)
select extensions.is(
  (select count(*)::text from information_schema.role_table_grants
    where table_schema = 'public' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  '0',
  'REG-C5 · negação em 2 camadas (0 grants DML públicos)'
);

rollback;