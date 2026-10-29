# Status

**Fase atual:** Fase 2 — inteligência de contas e construção de listas  
**Estado:** liberada  
**Última atualização:** 2026-10-29

## Progresso da Fase 2

**4/4 construídas (100%)**

| Task | Status |
|---|---|
| F2-T01 | ✅ concluída 2026-10-29 — matriz M1–M6, importação completa, contatos sensíveis e tela de usuários |
| F2-T02 | ✅ construída 2026-10-29 — pesquisa com proveniência, fila de pesquisa, tela `/pesquisa`; teste do cliente pendente |
| F2-T03 | ✅ construída 2026-10-29 — pontuação explicável versionada, tela `/pontuacao`; teste do cliente pendente |
| F2-T04 | ✅ construída 2026-10-29 — lista, revisão com motivo, coortes e CSV, tela `/lista`; teste do cliente pendente |

## Próximo marco

**Fase 2 construída por inteiro (4/4 tasks).** Falta apenas o teste do cliente das SPECs 2-001, 2-002 e 2-003, que depende de dado e decisão da SV (CNPJs do ICP, pesos do ICP v1 e aprovação da primeira coorte real).

**Pendência de dado da SV:** a base tem 308 contas com 0 CNPJ e 0 site válido. A pesquisa pela BrasilAPI exige CNPJ; sem ele, as contas vão corretamente para `pesquisa_necessaria` — mas o teste da SPEC-2-001 não demonstra enriquecimento. A SV precisa fornecer CNPJs do ICP ou autorizar fonte contratada.

A fase tem 4 tasks do agente e 4 testes do cliente, um no fim de cada SPEC (ver `04_fase-atual/fase.md`).

## Entregas

- Fase 1 encerrada com ressalvas em 2026-10-23 e arquivada em `05_entregas/fase-1/`.
- Implementação Skip vinculada em `05_entregas/sv-digital-app`.

## Decisões vigentes

- Supabase é o backend oficial (Postgres, Auth, RLS, auditoria, filas e Edge Functions).
- Skip é o frontend operacional.
- WhatsApp Cloud API é o canal primário; o agente opera sob supervisão e com takeover humano.
- Kommo permanece como CRM no curto prazo; Holdprint Web é integração futura.
