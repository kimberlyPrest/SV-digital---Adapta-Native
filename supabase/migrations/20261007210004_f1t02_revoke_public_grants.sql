-- F1-T02 endurecimento: revoga DML amplo concedido por padrão pelo Supabase
-- a anon/authenticated. Acesso continua VIA RLS (políticas); SELECT permanece
-- para o PostgREST aplicar RLS de leitura.
revoke insert, update, delete on all tables in schema public from anon, authenticated;
