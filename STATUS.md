# Status

**Fase atual:** Fase 2 — inteligência de contas e construção de listas  
**Estado:** liberada  
**Última atualização:** 2026-10-29

## Próximo marco

F2-T01: alinhar as permissões do Skip à matriz M1–M5, entregar a tela de importação completa, mostrar os contatos sensíveis ao admin no detalhe da conta e entregar a tela de usuários. Depois, F2-T02 a F2-T04 em sequência.

A fase tem 4 tasks do agente e 4 testes do cliente, um no fim de cada SPEC (ver `04_fase-atual/fase.md`).

## Entregas

- Fase 1 encerrada com ressalvas em 2026-10-23 e arquivada em `05_entregas/fase-1/`.
- Implementação Skip vinculada em `05_entregas/sv-digital-app`.

## Decisões vigentes

- Supabase é o backend oficial (Postgres, Auth, RLS, auditoria, filas e Edge Functions).
- Skip é o frontend operacional.
- WhatsApp Cloud API é o canal primário; o agente opera sob supervisão e com takeover humano.
- Kommo permanece como CRM no curto prazo; Holdprint Web é integração futura.
