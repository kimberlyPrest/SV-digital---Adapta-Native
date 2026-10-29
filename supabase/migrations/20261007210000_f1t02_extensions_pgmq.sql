-- F1-T02 migração 1/4: extensões — pgmq para filas privadas (schema dedicado)
create schema if not exists pgmq;
create extension if not exists pgmq with schema pgmq;
