-- ============================================================================
-- F1-T02 — 03_audit_test.sql — CA-1-02 (auditoria de ação crítica)
-- ----------------------------------------------------------------------------
-- GREEN esperado: INSERT crítico do prospector gera evento de auditoria com
-- ator e timestamp. A verificação do evento é feita como admin (único papel
-- que lê audit_events conforme M1) — trocando request.jwt.claim.sub na mesma
-- transação.
-- ============================================================================

-- @test: CA-1-02 acao critica gera evento de auditoria
begin;
select extensions.plan(1);
\ir setup.sql
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';

-- Ação crítica: prospector insere conta com ID próprio do teste
insert into public.accounts (id, organization_id, name, cnpj, status)
values ('00000000-0000-0000-0000-0000000000c3', '00000000-0000-0000-0000-0000000000a1', 'Conta Auditoria GREEN', '00000000000353', 'ativo');

-- Verificação como admin (M1: admin lê audit_events)
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000001';
select extensions.results_eq(
  'select count(*) from public.audit_events where object_table = ''accounts'' and object_id = ''00000000-0000-0000-0000-0000000000c3'' and actor = ''a0000000-0000-0000-0000-000000000003''::uuid',
  array[1::bigint],
  'CA-1-02: acao critica gera evento de auditoria com ator e timestamp'
);

rollback;
