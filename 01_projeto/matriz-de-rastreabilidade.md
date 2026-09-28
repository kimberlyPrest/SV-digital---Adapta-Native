# Matriz de rastreabilidade

| Fase | Origem no escopo | SPEC | Resultado e aceite | Tasks | Prova esperada | Status |
|---:|---|---|---|---|---|---|
| 1 | 4, 9, 10, 14 | SPEC-1-001 | Backend Supabase com CA-1-01 a CA-1-04 e CA-1-13 (matriz de permissões M1–M5) | F1-T01, F1-T02, F1-T03 | testes RLS, matriz de permissões provada por papel, migrações e inventário de secrets | Planejado |
| 1 | 5, 8, 9 | SPEC-1-002 | ICP, modelo e importação com CA-1-05 a CA-1-08 | F1-T04, F1-T05, F1-T06 | relatório de importação e reconciliação | Planejado |
| 1 | 2, 7, Fase 1 | SPEC-1-003 | Interface e painel com CA-1-09 a CA-1-12 | F1-T07, F1-T08, F1-T09 | URL, capturas e roteiro do Champion | Planejado |
| 2 | 5, 7.2, 7.3 | SPEC-2-001 | Pesquisa e proveniência com CA-2-01 a CA-2-04 | F2-T01, F2-T02, F2-T03 | jobs, evidências e teste de fonte | Planejado |
| 2 | 5.2, 7.4, 8 | SPEC-2-002 | Score explicável com CA-2-05 a CA-2-08 | F2-T04, F2-T05, F2-T06 | score runs e regressão de versão | Planejado |
| 2 | 7.5, 7.7, Fase 2 | SPEC-2-003 | Coorte aprovada com CA-2-09 a CA-2-12 | F2-T07, F2-T08, F2-T09 | export e aprovação da coorte | Planejado |
| 3 | 7.14, 8.16–20, 10.3 | SPEC-3-001 | Transporte WhatsApp com CA-3-01 a CA-3-04 | F3-T01, F3-T02, F3-T03 | eventos, filas e teste do número | Planejado |
| 3 | 7.9, 7.10, 7.14 | SPEC-3-002 | Agente e takeover com CA-3-05 a CA-3-08 | F3-T04, F3-T05, F3-T06 | corpus, replay e kill switch | Planejado |
| 3 | 7.6–7.9, 8.4–8.9 | SPEC-3-003 | Cadência aprovada com CA-3-09 a CA-3-12 | F3-T07, F3-T08, F3-T09 | política, batch report e opt out | Planejado |
| 3 | 7.10, 7.11, 10 | SPEC-3-004 | Reunião e CRM com CA-3-13 a CA-3-16 | F3-T10, F3-T11, F3-T12 | pacote, agenda e sync idempotente | Planejado |
| 4 | Fase 4, confiabilidade | SPEC-4-001 | Central de exceções com CA-4-01 a CA-4-04 | F4-T01, F4-T02, F4-T03 | runbook e auditoria | Planejado |
| 4 | 2.2, 7.12, Fase 4 | SPEC-4-002 | Analytics com CA-4-05 a CA-4-08 | F4-T04, F4-T05, F4-T06 | painel, export e decisão | Planejado |
| 4 | Loop de pesquisa | SPEC-4-003 | Ciclo de pesquisa com CA-4-09 a CA-4-12 | F4-T07, F4-T08, F4-T09 | relatório de ciclo e veredito | Planejado |
| 4 | Loop de qualificação | SPEC-4-004 | Ciclo WhatsApp com CA-4-13 a CA-4-16 | F4-T10, F4-T11, F4-T12 | amostra, violações e kill switch | Planejado |
| 4 | Loop de integridade | SPEC-4-005 | Integridade com CA-4-17 a CA-4-20 | F4-T13, F4-T14, F4-T15 | baseline, segunda volta e findings | Planejado |
| 5 | Indicadores e Fase 5 | SPEC-5-001 | Escala controlada com CA-5-01 a CA-5-04 | F5-T01, F5-T02, F5-T03 | painel e decisão versionada | Planejado |
| 5 | 4.3, 10, Fase 5 | SPEC-5-002 | Portabilidade CRM com CA-5-05 a CA-5-08 | F5-T04, F5-T05, F5-T06 | contract tests e rollback | Planejado |
| 5 | Loop de aprendizado | SPEC-5-003 | Aprendizado com CA-5-09 a CA-5-12 | F5-T07, F5-T08, F5-T09 | relatórios válido/inconclusivo | Planejado |
| 5 | Loop de supervisão | SPEC-5-004 | Supervisão com CA-5-13 a CA-5-16 | F5-T10, F5-T11, F5-T12 | alerta, pausa e retomada | Planejado |
| 5 | Matriz transversal | SPEC-5-005 | Validação global com CA-5-17 a CA-5-20 | F5-T13, F5-T14, F5-T15 | VF-01 a VF-12 e decisão de go-live | Planejado |

## Cobertura das decisões consolidadas

| Decisão | SPECs que executam ou protegem a decisão |
|---|---|
| Máquina de prospecção de novas contas B2B | SPEC-1-002, 2-001, 2-002, 2-003, 3-003 |
| Segmento inicial de mercados e varejo multiunidade | SPEC-1-002, 2-001, 2-002 |
| Supabase como backend central | SPEC-1-001 a 1-003 e todas as integrações posteriores |
| WhatsApp Cloud API como canal principal | SPEC-3-001 a 3-003 |
| Agente com qualificação e transferência humana | SPEC-3-002, 4-004, 5-004 |
| Kommo atual e Holdprint Web futuro | SPEC-3-004 e 5-002 |
| Cadência com aprovação humana | SPEC-2-003, 3-003, 5-001 |
| Reativação e pós-venda fora do escopo | protegido pelos limites das SPECs 3-002, 3-004 e 5-002 |
| Loops e agentes supervisionados | SPEC-4-003 a 4-005 e 5-003 a 5-004 |
| Validação de todas as fases | SPEC-5-005 |
