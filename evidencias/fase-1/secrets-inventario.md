# Inventário de secrets — SV Digital · Adapta Native (F1-T03)

**Data:** 2026-10-08 · **Responsável:** Juliano Dossena (Diego) — Administrador técnico  
**Princípio (AGENTS.md):** credenciais e chaves ficam somente em secrets do ambiente server-side; nunca no frontend, commits ou mensagens do WhatsApp.

## 1. Estado atual dos secrets

| Local | Conteúdo | Estado |
|---|---|---|
| Supabase Vault (`vault.secrets`) | — | **0 segredos cadastrados** (verificado 08/10) — correto para a Fase 1: nenhuma integração externa ativa |
| Edge Functions | nenhuma função implantada | sem secrets de função |
| Frontend Skip | `VITE_SUPABASE_URL` + `VITE_SUPABASE_PUBLISHABLE_KEY` | apenas chave PUBLISHABLE (pública por design) — RLS é a barreira; **nenhum service key no bundle** (CA-1-03) |
| WhatsApp Cloud API | não conectada nesta fase | credenciais entrarão só em secrets server-side quando a Fase 3 começar |

## 2. Política de gestão (vigorando)

- **Criação/rotação:** exclusivamente pelo Administrador técnico (Juliano Dossena), no painel do Supabase (Vault / Edge Function secrets).
- **Nunca** em código, migrações, testes, prompts, documentos ou mensagens — varredura de segredos executada em 08/10 no repositório inteiro: **0 achados**.
- **Service role:** `rolcanlogin = false` (verificado) — existe apenas para Edge Functions/workers server-side (PM-01).
- **Vault:** sem grants a `anon`/`authenticated` (verificado) — papéis humanos não leem segredos.
- **Quem pode ver o quê:** matriz M1/M5 — `admin` gerencia secrets e conectores; nenhum outro papel (SPEC-1-001).

## 3. Segredos previstos (futuro — cadastrar só quando a fase exigir)

| Secret | Fase | Armazenamento |
|---|---|---|
| `WHATSAPP_TOKEN` / `WHATSAPP_PHONE_ID` / `WHATSAPP_VERIFY_TOKEN` | 3 | Supabase Edge Function secrets |
| Chave do modelo de IA (versão/aprovação conforme escopo 7.14) | 3 | Supabase Edge Function secrets |
| Credencial do conector CRM (Kommo → Holdprint) | 3/5 | Supabase Edge Function secrets |

## 4. Recuperação (prova associada)

- Schema: reprodutível do zero pelas 7 migrações versionadas em `supabase/migrations/` (prova de catálogo em `spec-1-001-regressao.txt`, grupo REG-C).
- Dados: backup gerenciado pela plataforma (WAL `logical`); export de segurança é capacidade da Fase 5 (SPEC-5-002).
- Rollback de migração: reverter a última em homologação; nunca apagar produção para corrigir schema (SPEC-1-001).
