# GREEN — F1-T08: telas e painel inicial no Skip (SPEC-1-003)

**Data:** 2026-10-15/16 · **App:** https://pagina-de-login-sv-digital-51519.goskip.app (versão 0.0.3, ref c69a50e, publicada)
**QA Skip:** setup ok · static ok · build ok · integrations ok (3 versões: cb4803d telas, c69a50e fix imports)

## O que foi construído

| Tela/rota | Conteúdo | Estados implementados |
|---|---|---|
| `/` Visão por papel | navegação renderiza conforme papel (RN-144) + mensagem "Você acessa como…" | loading (spinner), sem papel (mensagem p/ falar com admin), sucesso |
| `/contas` | tabela das contas com status/origem/região + busca | loading (skeleton), vazio ("importe a base"), erro (retry), sucesso |
| `/correcoes` | fila RN-143 (só `importado_nao_reconciliado`) + modal de correção | loading, vazio ("sem pendências"), erro, sucesso + validação de formulário |
| `/painel` | 4 indicadores com valor + janela + cobertura (RN-141); filtro por origem | loading, erro, sucesso; zero ≠ ausente (—) ≠ incompleto (destaque amber) — CA-1-11 |

**Backend:** RPC `my_role(p_org)` (security definer, leitura do PRÓPRIO papel; EXECUTE só authenticated) + **correção de fundação**: helpers de RLS (`jwt_sub` etc.) agora usam `auth.uid()` — via HTTP o PostgREST não popula `request.jwt.claim.sub`, o que deixava TODA a matriz M1–M5 cega pela API (0 linhas para todos). Migração `f1t08_helpers_auth_uid` + `f1t08_my_role_rpc_v2`.

## Provas executadas (evidência real)

**Matriz M1–M5 via HTTP real (10/10 ok)** — com JWT de fixture por papel:
P1 vendedor INSERT negado (403) · P2 vendedor contatos [] · P3 leitor contatos [] · P4 leitor PATCH sem efeito · P5 prospector invalida lote sem efeito · P6 prospector INSERT permitido (201) · P7 lider DELETE sem efeito · P8 admin lê 308 · P9 admin importação negada (42501) · P10 leitor lê painel. **CA-1-09 provado: a API nega o que a UI oculta.**

**Interface real (browser):**
- Login fixture líder → redireciona a `/` → "Você acessa como Líder Comercial" + 3 links (Contas, Fila de correção, Painel)
- `/contas`: "200 contas na base" (limit 200), status "Importado · não reconciliado" e origem "Kommo"/"Fora de escopo" visíveis — captura: capturas/f1t08-painel-308.png (painel)
- `/painel`: 308 contas · 308 aguardando reconciliação · 308 sem CNPJ (incompleto destacado) · 0 ativas (zero real ≠ ausente) — CA-1-11 na tela
- `/correcoes`: fila com 100 contas (limit) → modal "Corrigir conta" → salvar SEM setor = erro de validação visível ("Informe o setor — campo obrigatório…") → preencher e salvar = sucesso "Conta movida para a fila de pesquisa" (mutação REAL end-to-end; efeito confirmado e devolvido ao estado original — resíduo 0)

## Critérios de aceite

- [x] **CA-1-09** — cada papel vê só telas/ações autorizadas E tentativa direta na API é negada (10/10 via HTTP)
- [x] **CA-1-11** — painel diferencia zero (0 ativas), ausente (—) e incompleto (308 sem CNPJ destacado)
- [x] **CA-1-12** — erros de rede/sessão: telas com retry sem mutação parcial (erro → "Tentar novamente"; sem catch que esconde falha)
- [ ] **CA-1-10** — roteiro completo do Champion sem editar banco: **teste humano pendente** (F1-T09 executa a demo formal por papel)

## Dívida deliberada (marcada no código)

- `use-papel.tsx`: org fixa em constante — seletor de organização quando houver >1 org ativa
- `/contas` sem paginação (limit 200) — paginar quando a base passar de 200 ativas
- correção da fila move para `pesquisa_necessaria`; reconciliação completa (owner + next_step + CNPJ) é a Fase 2

## Rollback

Versão anterior publicável (bdf5f80 — login puro); dados permanecem no Supabase.
