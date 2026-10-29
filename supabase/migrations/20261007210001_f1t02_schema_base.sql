-- F1-T02 migração 2/4: schema base — organizações, perfis, memberships,
-- auditoria, eventos de integração e entidades comerciais mínimas da Fase 1.
-- Reproduzível do zero; sem dados reais.

-- ============ Núcleo multi-organização ============
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','lider_comercial','prospector','vendedor','leitor')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

-- ============ Auditoria (RN-103) ============
create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  actor uuid,
  action text not null,
  object_table text not null,
  object_id uuid,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

-- ============ Eventos de integração (idempotência RN-104/8.16) ============
create table public.integration_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  event_type text not null,
  idempotency_key text not null unique,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'received' check (status in ('received','processed','failed','archived')),
  created_at timestamptz not null default now(),
  processed_at timestamptz
);

-- ============ Entidades comerciais mínimas (Fase 1) ============
create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  cnpj text,
  site text,
  sector text,
  region text,
  status text not null default 'ativo' check (status in ('ativo','pesquisa_necessaria','importado_nao_reconciliado','desqualificado','arquivado')),
  owner_id uuid references auth.users(id) on delete set null,
  next_step text,
  next_step_due date,
  source text,
  collected_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  account_id uuid references public.accounts(id) on delete cascade,
  name text not null,
  role text,
  email text,
  phone text,
  contact_preference text,
  source text,
  confidence text check (confidence in ('alta','media','baixa')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.icp_versions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  version int not null,
  name text not null,
  criteria jsonb not null default '{}'::jsonb,
  impediments jsonb not null default '[]'::jsonb,
  weights jsonb not null default '{}'::jsonb,
  published boolean not null default false,
  approved_by uuid references auth.users(id) on delete set null,
  valid_from date,
  valid_until date,
  created_at timestamptz not null default now(),
  unique (organization_id, version)
);

create table public.import_batches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  file_hash text not null,
  status text not null default 'importado_nao_reconciliado' check (status in ('importado_nao_reconciliado','reconciliado','invalidado')),
  imported_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (organization_id, file_hash)
);

-- ============ Índices essenciais ============
create index idx_memberships_user on public.memberships(user_id);
create index idx_memberships_org_active on public.memberships(organization_id, active);
create index idx_accounts_org on public.accounts(organization_id);
create index idx_contacts_org on public.contacts(organization_id);
create index idx_audit_object on public.audit_events(object_table, object_id);
create index idx_audit_actor on public.audit_events(actor, created_at);

-- ============ updated_at automático ============
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger trg_memberships_updated before update on public.memberships
  for each row execute function public.set_updated_at();
create trigger trg_accounts_updated before update on public.accounts
  for each row execute function public.set_updated_at();
create trigger trg_contacts_updated before update on public.contacts
  for each row execute function public.set_updated_at();

-- ============ Trigger de auditoria (RN-103 / CA-1-02) ============
create or replace function public.audit_row_change() returns trigger
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_actor uuid;
  v_before jsonb;
  v_after jsonb;
  v_action text;
begin
  v_actor := nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;

  if (tg_op = 'INSERT') then
    v_action := 'insert';
    v_after := to_jsonb(new);
  elsif (tg_op = 'UPDATE') then
    v_action := 'update';
    v_before := to_jsonb(old);
    v_after := to_jsonb(new);
  elsif (tg_op = 'DELETE') then
    v_action := 'delete';
    v_before := to_jsonb(old);
  end if;

  insert into public.audit_events (actor, action, object_table, object_id, before, after)
  values (
    v_actor,
    v_action,
    tg_table_name,
    coalesce((to_jsonb(new)->>'id')::uuid, (to_jsonb(old)->>'id')::uuid),
    v_before,
    v_after
  );

  return coalesce(new, old);
end $$;

create trigger trg_audit_accounts after insert or update or delete on public.accounts
  for each row execute function public.audit_row_change();
create trigger trg_audit_contacts after insert or update or delete on public.contacts
  for each row execute function public.audit_row_change();
create trigger trg_audit_memberships after insert or update or delete on public.memberships
  for each row execute function public.audit_row_change();
create trigger trg_audit_icp_versions after insert or update or delete on public.icp_versions
  for each row execute function public.audit_row_change();
create trigger trg_audit_import_batches after insert or update or delete on public.import_batches
  for each row execute function public.audit_row_change();

-- ============ Perfil automático para novo usuário (Auth) ============
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
