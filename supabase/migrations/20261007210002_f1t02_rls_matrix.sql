-- F1-T02 migração 3/4: RLS — matriz de permissões M1–M5 (SPEC-1-001) + deny by default.
-- Convenções: sem política = acesso NEGADO (PM-06). Toda política avalia a
-- membership ATIVA da organização do registro (PM-07 / CA-1-13).

-- ============ Helpers ============
create or replace function public.jwt_sub() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create or replace function public.role_in_org(org uuid) returns text
language sql stable security definer set search_path = public as $$
  select m.role from public.memberships m
  where m.user_id = public.jwt_sub()
    and m.organization_id = org
    and m.active = true
  limit 1
$$;

create or replace function public.is_active_member() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = public.jwt_sub() and m.active = true
  )
$$;

create or replace function public.has_global_role(roles text[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = public.jwt_sub()
      and m.active = true
      and m.role = any (roles)
  )
$$;

-- ============ Ativar RLS em TODAS as tabelas expostas ============
alter table public.organizations     enable row level security;
alter table public.profiles          enable row level security;
alter table public.memberships       enable row level security;
alter table public.audit_events      enable row level security;
alter table public.integration_events enable row level security;
alter table public.accounts          enable row level security;
alter table public.contacts          enable row level security;
alter table public.icp_versions      enable row level security;
alter table public.import_batches    enable row level security;

alter table public.organizations      force row level security;
alter table public.profiles           force row level security;
alter table public.memberships        force row level security;
alter table public.audit_events       force row level security;
alter table public.integration_events force row level security;
alter table public.accounts           force row level security;
alter table public.contacts           force row level security;
alter table public.icp_versions       force row level security;
alter table public.import_batches     force row level security;

-- ============ M1. organizations ============
create policy org_select on public.organizations
  for select using (public.is_active_member());
create policy org_insert on public.organizations
  for insert with check (public.has_global_role(array['admin']));
create policy org_update on public.organizations
  for update using (public.has_global_role(array['admin']))
  with check (public.has_global_role(array['admin']));
create policy org_delete on public.organizations
  for delete using (public.has_global_role(array['admin']));

-- ============ M1. profiles ============
create policy profile_self_select on public.profiles
  for select using (id = public.jwt_sub());
create policy profile_self_update on public.profiles
  for update using (id = public.jwt_sub())
  with check (id = public.jwt_sub());
create policy profile_admin_all on public.profiles
  for all using (public.has_global_role(array['admin']))
  with check (public.has_global_role(array['admin']));
create policy profile_lider_read on public.profiles
  for select using (public.has_global_role(array['lider_comercial']));

-- ============ M1. memberships ============
create policy memb_admin_all on public.memberships
  for all using (public.has_global_role(array['admin']))
  with check (public.has_global_role(array['admin']));
create policy memb_lider_read on public.memberships
  for select using (public.has_global_role(array['lider_comercial']));

-- ============ M1. audit_events ============
create policy audit_admin_read on public.audit_events
  for select using (public.has_global_role(array['admin']));
create policy audit_lider_read on public.audit_events
  for select using (public.has_global_role(array['lider_comercial']));

-- ============ M2. icp_versions ============
create policy icp_select on public.icp_versions
  for select using (public.is_active_member());
create policy icp_lider_write on public.icp_versions
  for insert with check (public.role_in_org(organization_id) = 'lider_comercial');
create policy icp_lider_update on public.icp_versions
  for update using (public.role_in_org(organization_id) = 'lider_comercial')
  with check (public.role_in_org(organization_id) = 'lider_comercial');
create policy icp_lider_delete on public.icp_versions
  for delete using (public.role_in_org(organization_id) = 'lider_comercial');

-- ============ M2/M3. accounts ============
create policy acct_select on public.accounts
  for select using (public.role_in_org(organization_id) is not null);
create policy acct_insert on public.accounts
  for insert with check (
    public.role_in_org(organization_id) in ('lider_comercial','prospector')
  );
create policy acct_update on public.accounts
  for update using (
    public.role_in_org(organization_id) in ('admin','lider_comercial','prospector')
  )
  with check (
    public.role_in_org(organization_id) in ('admin','lider_comercial','prospector')
  );
create policy acct_admin_delete on public.accounts
  for delete using (public.role_in_org(organization_id) = 'admin');

-- ============ M3. contacts ============
create policy cont_select on public.contacts
  for select using (
    public.role_in_org(organization_id) in ('admin','lider_comercial','prospector')
  );
create policy cont_insert on public.contacts
  for insert with check (
    public.role_in_org(organization_id) in ('lider_comercial','prospector')
  );
create policy cont_update on public.contacts
  for update using (
    public.role_in_org(organization_id) in ('admin','lider_comercial','prospector')
  )
  with check (
    public.role_in_org(organization_id) in ('admin','lider_comercial','prospector')
  );
create policy cont_admin_delete on public.contacts
  for delete using (public.role_in_org(organization_id) = 'admin');

-- ============ M4. import_batches ============
create policy imp_select on public.import_batches
  for select using (
    public.role_in_org(organization_id) in ('admin','lider_comercial','prospector')
  );
create policy imp_insert on public.import_batches
  for insert with check (
    public.role_in_org(organization_id) in ('lider_comercial','prospector')
  );
create policy imp_lider_update on public.import_batches
  for update using (public.role_in_org(organization_id) = 'lider_comercial')
  with check (public.role_in_org(organization_id) = 'lider_comercial');
create policy imp_admin_delete on public.import_batches
  for delete using (public.role_in_org(organization_id) = 'admin');

-- ============ M5. integration_events ============
-- server-side apenas: nenhuma política para papéis humanos (deny by default).
-- service_role (BYPASSRLS) acessa diretamente; PM-01 preservado.
