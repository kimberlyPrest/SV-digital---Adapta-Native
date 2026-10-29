-- F1-T05 hardening (verificação independente 2026-10-09): deny by default completo.
-- 1) Default privileges do Supabase concedem DML a authenticated em tabelas
--    novas criadas por migração — import_batch_rows é server-side apenas.
-- 2) Funções nascem com EXECUTE to PUBLIC — revogar de anon não basta.
revoke insert, update, delete on public.import_batch_rows from authenticated;
revoke execute on function public.import_commercial_base(uuid, text, text) from public;
revoke execute on function public.import_batch_report(uuid) from public;
