-- F1-T03: função server-side autorizada para revogação de membership.
-- Representa o caminho de administração (console/Edge Function com service_role):
-- escrita de memberships NÃO é feita por papéis humanos com grants diretos
-- (PM-01/RN-102). SECURITY DEFINER + audit trigger preservado.
-- Executável apenas por postgres/service_role (nada a anon/authenticated).
create or replace function public.revoke_member(p_user uuid, p_org uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.memberships
  set active = false
  where organization_id = p_org and user_id = p_user;
end $$;

revoke execute on function public.revoke_member(uuid, uuid) from anon, authenticated;
