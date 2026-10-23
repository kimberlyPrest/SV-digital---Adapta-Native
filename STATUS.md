# Status

**Fase atual:** Fase 2 — inteligência de contas e construção de listas  
**Estado:** liberada  
**Última atualização:** 2026-10-23

## Próximo marco

F2-T01: alinhar as permissões do Skip à matriz M1–M5 (importação para liderança, contatos sensíveis para admin) e entregar a tela de usuários; em seguida, pesquisa e enriquecimento com proveniência (SPEC-2-001).

## Entregas

- Fase 1 encerrada com ressalvas em 2026-10-23 e arquivada em `05_entregas/fase-1/`.
- Implementação Skip vinculada em `05_entregas/sv-digital-app`.

## Decisões vigentes

- Supabase é o backend oficial (Postgres, Auth, RLS, auditoria, filas e Edge Functions).
- Skip é o frontend operacional.
- WhatsApp Cloud API é o canal primário; o agente opera sob supervisão e com takeover humano.
- Kommo permanece como CRM no curto prazo; Holdprint Web é integração futura.
