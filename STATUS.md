# Status

**Fase atual:** Fase 1 — fundação segura, modelo comercial e painel inicial  
**Estado:** planejada  
**Última atualização:** 2026-09-22

## Próximo marco

Criar o projeto Supabase, validar o isolamento por organização/papel e preparar fixtures do modelo comercial antes de ativar qualquer integração com dados reais.

## Decisões vigentes

- Supabase é o backend oficial (Postgres, Auth, RLS, auditoria, filas e Edge Functions).
- Skip é o frontend operacional.
- WhatsApp Cloud API é o canal primário; o agente opera sob supervisão e com takeover humano.
- Kommo permanece como CRM no curto prazo; Holdprint Web é integração futura.
