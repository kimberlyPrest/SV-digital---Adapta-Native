-- F1-T02 migração 4/4: fila privada (Supabase Queues via pgmq).
-- Jobs assíncronos consumidos apenas server-side (service_role, BYPASSRLS).
select pgmq.create('jobs');
revoke execute on all functions in schema pgmq from anon, authenticated;
revoke usage on schema pgmq from anon, authenticated;
