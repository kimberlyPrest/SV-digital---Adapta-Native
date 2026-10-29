# AP-2026-10-16-postgrest-auth-uid — jwt_sub() cego via HTTP + página em branco por import faltante

**Task**: F1-T08 (SPEC-1-003) · **Momento**: implementação e teste funcional

## Sinais (2, com evidência)
1. Helpers de RLS baseados em `current_setting('request.jwt.claim.sub')` retornam NULL em TODA chamada HTTP real: o PostgREST do Supabase popula `request.jwt.claims` (JSON) e `auth.uid()`, não o GUC claim.sub. Com GUC simulado via MCP (`set local request.jwt.claim.sub`) tudo passava — prova cega. Sintoma no app: qualquer usuário via API via 0 linhas.
2. Componente React com contexto sem `import { createContext, useContext }` compila no build do Skip (QA ok) e dá página EM BRANCO em runtime (root vazio) — sem erro visível na tela.

## Regras reutilizáveis
- RLS/helpers de sessão usam SEMPRE `auth.uid()` (ou `request.jwt.claims->>'sub'`); testar via HTTP com JWT real, não só via MCP com GUC simulado.
- Página em branco no React = suspeita nº 1: import faltando no provider/contexto. Verificar root vazio com `document.getElementById('root').innerHTML`.
- Publicar no Skip exige `apply_changes` ANTES do `publish` (publish sem apply publica a ref antiga).

## Aplicado em
Migração f1t08_helpers_auth_uid (jwt_sub com fallback auth.uid()); fix do use-papel.tsx; fluxo apply→publish validado (v0.0.2→0.0.3).
