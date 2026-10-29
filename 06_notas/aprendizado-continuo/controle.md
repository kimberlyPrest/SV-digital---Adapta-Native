# Controle de aprendizado contínuo

- 2026-10-07T18:25-03:00 · task F1-T01 · capturado: 06_notas/aprendizado-continuo/AP-2026-10-07-1825-suite-pgtap-via-mcp.md (2 sinais: execução pgtap via MCP com rollback; lições de plataforma Supabase gerenciado)- 2026-10-08T10:22-03:00 · task F1-T02 · capturado: 06_notas/aprendizado-continuo/AP-2026-10-08-1022-hardening-grants-e-provas-negativas.md (2 sinais: revoke de grants padrão do Supabase; semântica de provas negativas RLS)
- 2026-10-08T17:03-03:00 · task F1-T04 · capturado: 06_notas/aprendizado-continuo/AP-2026-10-08-1545-revoke-antes-da-regra.md (provas RED de regra inexistente caem no 42501 do revoke antes da regra; GREEN da F1-T05 exige a regra, não só o revoke)
AP-2026-10-09-1045 — default privileges Supabase (DML sistema + EXECUTE PUBLIC) — aplicado na F1-T05
AP-2026-10-15-f1t06 — payload MCP/staging+md5/pgtap plan/atomicidade/sanitização Kommo — aplicado na F1-T06
AP-2026-10-15-f1t07 — RED em superfície real + reprodução assistida em divergência de teste — aplicado na F1-T07
AP-2026-10-15-gotrue — formato GoTrue em seed SQL + provar caminho oposto antes de atribuir causa — aplicado na F1-T08
AP-2026-10-16-postgrest — auth.uid() em RLS HTTP + página em branco/import faltante + apply antes de publish — aplicado na F1-T08
AP-2026-10-22-f1t09-demo — sem sinal reutilizável: demo formal seguida sem divergência; padrão "conta DEMO nomeada com 0 para aparecer no topo da fila" pode servir para futuras demos com fila.
AP-2026-10-27-fase2-sem-spec — sem sinal reutilizável: não é aprendizado de engenharia, é ausência de handoff (plano/SPEC da Fase 2 não liberados pela consultoria). Registro em changelog como DÚVIDA.
AP-2026-10-29-testes-sem-bundler — lógica pura em .ts testável com node --test (sem bundler); grant em função security definer só junto da checagem de autorização; QA do Skip é o build oficial (vite local inviável).
