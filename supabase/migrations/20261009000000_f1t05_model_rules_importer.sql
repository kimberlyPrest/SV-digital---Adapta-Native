-- F1-T05 (SPEC-1-002): regras do modelo comercial + importador idempotente.
-- Transforma o RED da F1-T04 em GREEN: CA-1-05 a CA-1-08.
-- ORDEM: tabelas → colunas → índices → grants → RLS/policies → triggers → constraint → funções.

-- ============ 1. Funil — taxonomia controlada (nomes de clientes NÃO são etapas) ============
create table public.funnel_stages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  position int not null default 0,
  is_terminal boolean not null default false,
  created_at timestamptz not null default now(),
  unique (organization_id, name)
);

alter table public.accounts add column exception_reason text;
alter table public.accounts add column funnel_stage_id uuid references public.funnel_stages(id) on delete set null;

-- ============ 2. Rastreabilidade por linha de importação ============
create table public.import_batch_rows (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.import_batches(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  line_number int not null,
  legacy_stage text,
  responsible_name text,
  category text not null check (category in ('importado','duplicado','incompleto','rejeitado')),
  reason text,
  account_id uuid references public.accounts(id) on delete set null,
  contact_id uuid references public.contacts(id) on delete set null,
  raw jsonb,
  created_at timestamptz not null default now()
);

create index idx_ibrows_batch on public.import_batch_rows(batch_id);

-- ============ 3. Taxonomia padrão semeada na criação de cada organização ============
create or replace function public.seed_default_funnel() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.funnel_stages (organization_id, name, position, is_terminal) values
    (new.id, 'prospeccao', 1, false),
    (new.id, 'contato_inicial', 2, false),
    (new.id, 'qualificacao', 3, false),
    (new.id, 'reuniao_agendada', 4, false),
    (new.id, 'handoff', 5, false),
    (new.id, 'desqualificado', 6, true),
    (new.id, 'sem_resposta', 7, true);
  return new;
end $$;

create trigger trg_seed_default_funnel after insert on public.organizations
  for each row execute function public.seed_default_funnel();

-- ============ 4. Superfície de escrita refinada (ajuste da F1-T02) ============
-- A matriz M1–M5 espera escritas mediadas pelo app (PostgREST) com RLS como
-- autorização por papel. O revoke amplo da F1-T02 bloqueava o caminho do app
-- (regra de negócio nunca era alcançada — só o revoke). anon: nunca escreve.
-- authenticated: DML apenas nas tabelas de negócio (RLS decide por papel).
-- audit_events, integration_events e import_batch_rows: server-side apenas.
revoke insert, update, delete on all tables in schema public from anon;
grant insert, update, delete on
  public.organizations, public.profiles, public.memberships,
  public.accounts, public.contacts, public.icp_versions, public.import_batches,
  public.funnel_stages
  to authenticated;

-- ============ 5. RLS das novas tabelas ============
alter table public.funnel_stages enable row level security;
alter table public.funnel_stages force row level security;
alter table public.import_batch_rows enable row level security;
alter table public.import_batch_rows force row level security;

-- funnel_stages: leitura p/ membros ativos; admin RU; lider CRUD (M2)
create policy fs_select on public.funnel_stages
  for select using (public.is_active_member());
create policy fs_insert on public.funnel_stages
  for insert with check (public.role_in_org(organization_id) in ('admin','lider_comercial'));
create policy fs_update on public.funnel_stages
  for update using (public.role_in_org(organization_id) in ('admin','lider_comercial'))
  with check (public.role_in_org(organization_id) in ('admin','lider_comercial'));
create policy fs_delete on public.funnel_stages
  for delete using (public.role_in_org(organization_id) = 'lider_comercial');

-- import_batch_rows: leitura p/ admin/lider/prospector; escrita server-side apenas
create policy ibrows_select on public.import_batch_rows
  for select using (public.role_in_org(organization_id) in ('admin','lider_comercial','prospector'));

-- ============ 6. RN-124: ICP publicado é imutável (CA-1-05) ============
create or replace function public.icp_published_immutable() returns trigger
language plpgsql as $$
begin
  if tg_op = 'UPDATE' and old.published then
    if new.criteria is distinct from old.criteria
       or new.impediments is distinct from old.impediments
       or new.weights is distinct from old.weights then
      raise exception 'RN-124: conteudo de versao publicada de ICP e imutavel; corrija criando nova versao' using errcode = 'P0001';
    end if;
  elsif tg_op = 'DELETE' and old.published then
    raise exception 'RN-124: versao publicada de ICP nao pode ser removida' using errcode = 'P0001';
  end if;
  return coalesce(new, old);
end $$;

create trigger trg_icp_published_immutable
  before update or delete on public.icp_versions
  for each row execute function public.icp_published_immutable();

-- ============ 7. RN-121: ativo reconciliado exige owner + próximo passo ou exceção (CA-1-07) ============
alter table public.accounts add constraint rn121_active_requires_owner_next_step
  check (
    status <> 'ativo'
    or (owner_id is not null and (next_step is not null or exception_reason is not null))
  );

-- ============ 8. Importador idempotente (CA-1-06 / RN-16) ============
create or replace function public.import_commercial_base(
  p_organization_id uuid,
  p_file_hash text,
  p_csv text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_batch_id uuid;
  v_lines text[];
  v_header text[];
  v_fields text[];
  v_row jsonb;
  v_i int;
  v_nome text;
  v_cnpj text;
  v_existing uuid;
  v_account_id uuid;
  v_source text;
  v_imported int := 0;
  v_duplicated int := 0;
  v_incomplete int := 0;
  v_rejected int := 0;
begin
  -- M4/RN-125: só lider_comercial ou prospector da organização executa importação
  v_role := public.role_in_org(p_organization_id);
  if v_role not in ('lider_comercial','prospector') then
    raise exception 'RN-125/M4: papel sem permissao de importacao' using errcode = '42501';
  end if;

  if p_file_hash is null or length(trim(p_file_hash)) = 0 then
    raise exception 'import: hash do arquivo obrigatorio' using errcode = 'P0001';
  end if;
  if p_csv is null or length(trim(p_csv)) = 0 then
    raise exception 'import: CSV vazio' using errcode = 'P0001';
  end if;

  -- idempotência do lote: hash único por organização; reimport referencia o lote anterior
  select id into v_batch_id
  from public.import_batches
  where organization_id = p_organization_id and file_hash = p_file_hash;
  if v_batch_id is not null then
    return jsonb_build_object(
      'batch_id', v_batch_id,
      'idempotent_replay', true,
      'status', 'lote_ja_importado'
    );
  end if;

  insert into public.import_batches (organization_id, file_hash, imported_by)
  values (p_organization_id, p_file_hash, public.jwt_sub())
  returning id into v_batch_id;

  v_lines := string_to_array(replace(p_csv, chr(13) || chr(10), chr(10)), chr(10));
  v_header := array(select trim(x) from unnest(string_to_array(lower(trim(v_lines[1])), ',')) as x);

  -- erro obrigatório: coluna ausente
  if not ('nome' = any(v_header)) or not ('cnpj' = any(v_header)) then
    raise exception 'import: coluna obrigatoria ausente no cabecalho (nome, cnpj)' using errcode = 'P0001';
  end if;

  for v_i in 2 .. coalesce(array_length(v_lines, 1), 1) loop
    if trim(v_lines[v_i]) = '' then
      continue;
    end if;
    v_fields := string_to_array(v_lines[v_i], ',');
    if cardinality(v_fields) < cardinality(v_header) then
      v_rejected := v_rejected + 1;
      insert into public.import_batch_rows (batch_id, organization_id, line_number, category, reason)
      values (v_batch_id, p_organization_id, v_i, 'rejeitado', 'linha com menos campos que o cabecalho');
      continue;
    end if;
    v_row := jsonb_build_object(
      'nome', v_fields[array_position(v_header, 'nome')],
      'cnpj', v_fields[array_position(v_header, 'cnpj')],
      'site', v_fields[array_position(v_header, 'site')],
      'setor', v_fields[array_position(v_header, 'setor')],
      'regiao', v_fields[array_position(v_header, 'regiao')],
      'estagio_legado', v_fields[array_position(v_header, 'estagio_legado')],
      'responsavel', v_fields[array_position(v_header, 'responsavel')],
      'origem', v_fields[array_position(v_header, 'origem')],
      'contato_nome', v_fields[array_position(v_header, 'contato_nome')],
      'contato_cargo', v_fields[array_position(v_header, 'contato_cargo')],
      'contato_telefone', v_fields[array_position(v_header, 'contato_telefone')],
      'contato_email', v_fields[array_position(v_header, 'contato_email')],
      'contato_fonte', v_fields[array_position(v_header, 'contato_fonte')],
      'contato_data_verificacao', v_fields[array_position(v_header, 'contato_data_verificacao')]
    );
    v_nome := nullif(trim(coalesce(v_row ->> 'nome', '')), '');
    if v_nome is null then
      v_incomplete := v_incomplete + 1;
      insert into public.import_batch_rows (batch_id, organization_id, line_number, category, reason, raw)
      values (v_batch_id, p_organization_id, v_i, 'incompleto', 'nome ausente', v_row);
      continue;
    end if;
    v_cnpj := regexp_replace(coalesce(v_row ->> 'cnpj', ''), '[^0-9]', '', 'g');
    if v_cnpj <> '' and length(v_cnpj) <> 14 then
      v_rejected := v_rejected + 1;
      insert into public.import_batch_rows (batch_id, organization_id, line_number, category, reason, raw)
      values (v_batch_id, p_organization_id, v_i, 'rejeitado', 'CNPJ invalido (esperados 14 digitos)', v_row);
      continue;
    end if;
    -- RN-122: duplicidade por CNPJ normalizado — mesma conta sugerida
    if v_cnpj <> '' then
      select id into v_existing from public.accounts
      where organization_id = p_organization_id and cnpj = v_cnpj
      limit 1;
    else
      v_existing := null;
    end if;
    if v_existing is not null then
      v_duplicated := v_duplicated + 1;
      insert into public.import_batch_rows (batch_id, organization_id, line_number, legacy_stage, responsible_name, category, reason, account_id, raw)
      values (v_batch_id, p_organization_id, v_i,
        nullif(trim(coalesce(v_row ->> 'estagio_legado', '')), ''),
        nullif(trim(coalesce(v_row ->> 'responsavel', '')), ''),
        'duplicado', 'CNPJ ja presente na base (RN-122: mesma conta sugerida)', v_existing, v_row);
      continue;
    end if;
    insert into public.accounts (organization_id, name, cnpj, site, sector, region, status, source)
    values (p_organization_id, v_nome, nullif(v_cnpj, ''),
      nullif(trim(coalesce(v_row ->> 'site', '')), ''),
      nullif(trim(coalesce(v_row ->> 'setor', '')), ''),
      nullif(trim(coalesce(v_row ->> 'regiao', '')), ''),
      'importado_nao_reconciliado',
      nullif(trim(coalesce(v_row ->> 'origem', '')), ''))
    returning id into v_account_id;
    v_imported := v_imported + 1;
    -- RN-123: contato sem fonte/data nunca nasce verificável (pesquisa_necessaria)
    if nullif(trim(coalesce(v_row ->> 'contato_nome', '')), '') is not null then
      v_source := nullif(trim(coalesce(v_row ->> 'contato_fonte', '')), '');
      insert into public.contacts (organization_id, account_id, name, role, email, phone, source, confidence, verified_at)
      values (
        p_organization_id, v_account_id,
        trim(v_row ->> 'contato_nome'),
        nullif(trim(coalesce(v_row ->> 'contato_cargo', '')), ''),
        nullif(trim(coalesce(v_row ->> 'contato_email', '')), ''),
        nullif(trim(coalesce(v_row ->> 'contato_telefone', '')), ''),
        v_source,
        case when v_source is null then 'baixa' else 'media' end,
        case when v_source is null then null::timestamptz
             else nullif(v_row ->> 'contato_data_verificacao', '')::timestamptz end
      );
    end if;
    insert into public.import_batch_rows (batch_id, organization_id, line_number, legacy_stage, responsible_name, category, account_id, raw)
    values (v_batch_id, p_organization_id, v_i,
      nullif(trim(coalesce(v_row ->> 'estagio_legado', '')), ''),
      nullif(trim(coalesce(v_row ->> 'responsavel', '')), ''),
      'importado', v_account_id, v_row);
  end loop;

  return jsonb_build_object(
    'batch_id', v_batch_id,
    'idempotent_replay', false,
    'total_rows', v_imported + v_duplicated + v_incomplete + v_rejected,
    'importados', v_imported,
    'duplicados', v_duplicated,
    'incompletos', v_incomplete,
    'rejeitados', v_rejected
  );
end $$;

revoke execute on function public.import_commercial_base(uuid, text, text) from anon;
grant execute on function public.import_commercial_base(uuid, text, text) to authenticated;

-- ============ 9. Relatório do lote (CA-1-08) ============
create or replace function public.import_batch_report(p_batch_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org uuid;
  v_result jsonb;
begin
  select organization_id into v_org from public.import_batches where id = p_batch_id;
  if v_org is null then
    raise exception 'lote nao encontrado' using errcode = 'P0002';
  end if;
  if public.role_in_org(v_org) not in ('admin','lider_comercial','prospector') then
    raise exception 'M4: papel sem acesso ao relatorio do lote' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'batch_id', b.id,
    'status', b.status,
    'total_rows', count(r.id),
    'importados', count(r.id) filter (where r.category = 'importado'),
    'duplicados', count(r.id) filter (where r.category = 'duplicado'),
    'incompletos', count(r.id) filter (where r.category = 'incompleto'),
    'rejeitados', count(r.id) filter (where r.category = 'rejeitado')
  )
  into v_result
  from public.import_batches b
  left join public.import_batch_rows r on r.batch_id = b.id
  where b.id = p_batch_id
  group by b.id, b.status;
  return v_result;
end $$;

revoke execute on function public.import_batch_report(uuid) from anon;
grant execute on function public.import_batch_report(uuid) to authenticated;
