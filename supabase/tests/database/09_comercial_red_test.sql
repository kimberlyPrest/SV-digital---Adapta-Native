-- ============================================================================
-- F1-T04 — 09_comercial_red_test.sql — RED do modelo comercial (SPEC-1-002)
-- ----------------------------------------------------------------------------
-- Critério binário: RED reproduz duplicidade e lacunas.
-- Estes testes FALHAM hoje porque o importador e as validações (CA-1-05 a
-- CA-1-08, RN-121..125) ainda não existem — GREEN chega na F1-T05.
-- Cada teste roda em transação com rollback (runner). Dados 100% fictícios.
-- ============================================================================

-- @test: CA-1-05 ICP publicado é imutável (edição retroativa negada)
begin;
select extensions.plan(1);
\ir setup.sql
-- ICP v1 publicada na fixture (approved_by = lider). Tentativa: editar a v1
-- publicada. GREEN (F1-T05): trigger/constraint bloqueia edições em versão
-- publicada. RED (hoje): o UPDATE é aceito → asserção falha.
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000002';
select extensions.throws_ok(
  'update public.icp_versions set criteria = ''{"segmento":"alterado"}''::jsonb where organization_id = ''00000000-0000-0000-0000-0000000000a1'' and version = 1',
  'P0001',
  NULL,
  'CA-1-05: publicar ICP v1 nao permite edicao retroativa'
);
rollback;

-- @test: CA-1-06 importar o mesmo arquivo duas vezes não duplica
begin;
select extensions.plan(3);
\ir setup.sql
-- O importador (Edge Function import-commercial-base) não existe: a tabela
-- import_batches registra lotes, mas nada importa contas. O teste chama a
-- função esperada do importador — RED: função inexistente (erro 42883).
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.has_function(
  'public.import_commercial_base',
  'CA-1-06: importador existe (função import_commercial_base)'
);
select extensions.throws_ok(
  'select public.import_commercial_base(''redfixture-hash-001'', ''csv-completo'')',
  NULL,
  NULL,
  'CA-1-06: primeira importação processa sem erro'
);
select extensions.results_eq(
  'select count(*) from public.accounts where organization_id = ''00000000-0000-0000-0000-0000000000a1''',
  array[10::bigint],
  'CA-1-06: reimportar o MESMO hash não duplica contas (12 linhas → 10 contas únicas)'
);
rollback;

-- @test: CA-1-07 ativo reconciliado exige owner e próximo passo ou exceção
begin;
select extensions.plan(1);
\ir setup.sql
-- GREEN (F1-T05): constraint parcial — conta reconciliada sem owner nem
-- next_step viola. RED (hoje): UPDATE aceito → asserção falha.
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.throws_ok(
  'update public.accounts set status = ''ativo'', owner_id = null, next_step = null where organization_id = ''00000000-0000-0000-0000-0000000000a1'' and id = ''00000000-0000-0000-0000-0000000000c1''',
  'P0001',
  NULL,
  'CA-1-07: ativo reconciliado sem owner/next_step é rejeitado (RN-121)'
);
rollback;

-- @test: CA-1-08 relatório separa importados duplicados incompletos rejeitados
begin;
select extensions.plan(1);
\ir setup.sql
-- GREEN (F1-T05): função de relatório do lote retorna as 4 categorias.
-- RED (hoje): função não existe → erro 42883.
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.has_function(
  'public.import_batch_report',
  'CA-1-08: relatório do lote existe (função import_batch_report)'
);
rollback;

-- @test: RN-123 contato sem fonte fica pesquisa_necessaria
begin;
select extensions.plan(1);
\ir setup.sql
-- GREEN (F1-T05): importador marca contato sem fonte/data como
-- pesquisa_necessaria (RN-123). RED (hoje): nada impede contato "pronto".
-- Nota: INSERT direto em contacts por authenticated foi revogado na F1-T02;
-- a escrita real virá do importador server-side (F1-T05). Fixture via caminho autorizado:
set local role postgres;
insert into public.contacts (id, organization_id, name, email, phone)
values ('00000000-0000-0000-0000-0000000000d9', '00000000-0000-0000-0000-0000000000a1', 'Contato Sem Fonte', 'semfonte@fixture.test', '+5551000000000');
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.results_eq(
  'select count(*) from public.contacts where id = ''00000000-0000-0000-0000-0000000000d9'' and source is null and verified_at is not null',
  array[0::bigint],
  'RN-123: contato sem fonte NÃO fica verificável (importador marca pesquisa_necessaria)'
);
rollback;

-- @test: RN-125 prospector não invalida lote nem publica ICP (revalidação na SPEC)
begin;
select extensions.plan(2);
\ir setup.sql
-- RLS da F1-T02 já cobre: prospector não tem UPDATE em import_batches nem
-- INSERT em icp_versions. Revalidação no contexto da SPEC-1-002 (RN-125).
set local role authenticated;
set local request.jwt.claim.sub = 'a0000000-0000-0000-0000-000000000003';
select extensions.throws_ok(
  'update public.import_batches set status = ''invalidado'' where organization_id = ''00000000-0000-0000-0000-0000000000a1''',
  '42501',
  NULL,
  'RN-125: prospector não invalida lote (negado e auditado)'
);
select extensions.throws_ok(
  'insert into public.icp_versions (organization_id, version, name, criteria, published) values (''00000000-0000-0000-0000-0000000000a1'', 99, ''ICP Prospector'', ''{}''::jsonb, true)',
  '42501',
  NULL,
  'RN-125: prospector não publica ICP (negado e auditado)'
);
rollback;