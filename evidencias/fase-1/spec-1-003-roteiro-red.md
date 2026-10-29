# ROTEIRO RED + ESTADOS DA INTERFACE — F1-T07 (SPEC-1-003)

**Data:** 2026-10-15 · **Autorização:** "Pode implementar com esses defaults" (2026-10-15 10:46)
**Teste humano:** APROVADO (2026-10-15) — champion reproduziu R01 duas vezes com a senha correta: "Erro de autenticação". Na 1ª tentativa relatou ter entrado no sistema; debug executado (reexecução assistida confirmou a falha) e 2º teste do champion confirmou o RED.
**Projeto Skip:** SV Digital (id 61901) · **URL produção:** https://pagina-de-login-sv-digital-51519.goskip.app (publicada nesta task: ref bdf5f80)
**Backend:** Supabase wwdwaaerurtabobcsppb · org `SV Digital` · base real: 308 contas / 244 contatos (lote 36c6330a)

## Veredito RED

**O roteiro FALHA pelas telas ausentes — como a SPEC exige (RED antes da F1-T08).**

> **CORREÇÃO (2026-10-15 14:10, pós-fechamento):** durante a análise da F1-T08 foi provado que o app já está conectado ao Supabase (login real funciona com a senha correta do seed; fixtures autenticam após correção dos campos de token do GoTrue). A causa originalmente atribuída ao R01 ('app sem conexão') estava ERRADA — a falha do 2º teste do champion veio de senha errada citada no próprio roteiro. O RED do roteiro completo segue válido pelas telas ausentes (R02–R07).

| Passo | O que prova | Resultado hoje |
|---|---|---|
| R01 Login | autenticação real | ⚠️ CORRIGIDO PÓS-FECHAMENTO (2026-10-15 14:10): o app ESTÁ conectado ao Supabase real (env vars presentes; login de juliano com a senha correta do seed FUNCIONA — access_token provado via API). O "Erro de autenticação" ocorre apenas com senha ERRADA — o roteiro de teste citava senha inexistente (erro do roteiro, não do app); o 1º teste do champion ("entrei no sistema") era o correto. RED do ROTEIRO COMPLETO permanece válido: pós-login só existe a página de boas-vindas placeholder — R02–R07 falham por telas ausentes. Capturas mantidas como registro do comportamento com senha errada. |
| R02 Visão por papel | RN-144: tela renderiza conforme papel | ❌ FALHA (esperado): não existem rotas pós-login |
| R03 Contas (revisar/origem) | RN-143: registro incompleto visível na fila | ❌ FALHA (esperado): tela não existe |
| R04 Correção de pendência | RN-142: ação sem permissão oculta/desabilitada E negada server-side | ❌ FALHA (esperado): tela não existe |
| R05 Painel | RN-141: valor + janela + cobertura; zero ≠ ausente ≠ incompleto | ❌ FALHA (esperado): tela não existe |
| R06 Estados obrigatórios | loading/vazio/erro/sucesso em cada tela | ❌ FALHA (esperado): sem telas, sem estados |
| R07 Erros obrigatórios | 401, 403, timeout, lista vazia, validação de formulário | ❌ FALHA (esperado): 401 provado no R01; demais sem superfície |

**Prova server-side da matriz (executada nesta task — 10/10 ok, `spec-1-003-red-server.txt`):**
a interface da F1-T08 NÃO pode confiar em ocultação client-side — o banco já nega o que a matriz nega:

| # | Papel | Prova | Resultado |
|---|---|---|---|
| P1 | vendedor | INSERT em accounts → 42501 | ok |
| P2 | vendedor | contatos invisíveis (0 linhas) | ok |
| P3 | leitor | contatos invisíveis ("abrir telefone" negado) | ok |
| P4 | leitor | UPDATE em accounts = efeito nulo | ok |
| P5 | prospector | invalidar lote = efeito nulo (lider apenas) | ok |
| P6 | prospector | INSERT em conta permitido (M3) | ok |
| P7 | lider | DELETE de conta = efeito nulo (admin apenas) | ok |
| P8 | admin | lê base completa (308) | ok |
| P9 | admin | executar importação → 42501 (RN-125/M4) | ok |
| P10 | leitor | lê painel de contas (308 — leitura permitida) | ok |

## Fixtures por papel (criadas e COMMITADAS nesta task)

| Papel | E-mail | user id | Senha |
|---|---|---|---|
| admin | f1t07.admin@svdigital.ind.br | a1000000-…-001 | registrada em work/f1t07/credenciais.md (FORA DO GIT) |
| lider_comercial | f1t07.lider@svdigital.ind.br | a1000000-…-002 | idem |
| prospector | f1t07.prospector@svdigital.ind.br | a1000000-…-003 | idem |
| vendedor | f1t07.vendedor@svdigital.ind.br | a1000000-…-004 | idem |
| leitor | f1t07.leitor@svdigital.ind.br | a1000000-…-005 | idem |

Todos membros ativos da org `SV Digital` (profiles criados pelo trigger). Resíduo: 0 (provas em transação com rollback; fixtures persistentes são a pré-condição declarada da F1-T08/T09).

## Roteiro GREEN (para a F1-T08 executar — especificação, ainda não executável)

Para cada papel, fazer login e percorrer: **login → visão do papel → contas → correção permitida → tentativa da ação proibida → painel → logout**.

- **admin**: gerenciar usuários/configurações ✓ · executar importação ✗ (botão ausente/desabilitado + API 42501)
- **lider_comercial**: publicar ICP, aprovar lote, fila de correção ✓ · excluir conta ✗ (API: efeito nulo)
- **prospector**: importar, revisar, corrigir registro ✓ · invalidar lote ✗ (controle ausente + API efeito nulo)
- **vendedor**: ler contas/coortes ✓ · abrir contato com telefone ✗ (dados não renderizados + 0 linhas na API) · importar base ✗ (42501)
- **leitor**: painéis e indicadores ✓ · qualquer mutação ✗ (efeito nulo) · contatos ✗ (0 linhas)

## Estados e erros obrigatórios (checklist da F1-T08)

| Tela | Loading | Vazio | Erro | Sucesso |
|---|---|---|---|---|
| Login | botão desabilitado enquanto autentica | — | mensagem amigável + correlation id | redireciona à visão do papel |
| Contas | skeleton/spinner | "Nenhuma conta — importar base" (explica próxima ação) | banner de erro + retry | lista com origem visível |
| Correção | spinner no submit | fila vazia: "Sem pendências" | erro de campo inline (validação) | confirmação e fila atualizada |
| Painel | skeleton | zero ≠ ausente ≠ incompleto (RN-141: valor + janela + cobertura) | banner + último dado válido | filtros aplicados |
| Erros globais | — | — | 401 → logout e login; 403 → mensagem de permissão; timeout → retry sem mutação parcial (CA-1-12) | — |

## Contrato para a F1-T08

1. Conectar o app ao Supabase (auth real; anon key pública no frontend — NUNCA service role).
2. Implementar rotas/telas do roteiro com os 4 estados por tela.
3. CA-1-09: cada prova "proibida" deve falhar na API (captura de 403/42501), não só na UI.
4. CA-1-11: painel diferencia zero / ausente / incompleto.
5. Manter a versão publicável atual como rollback.
