# SPEC-2-000 Alinhamento de permissões e extensão da matriz para a Fase 2

**Fase:** 2  
**Status:** planejada  
**Dono:** Champion SV  
**Origem no escopo:** seções 3, 14.1 e 15.7; matriz M1–M5 da SPEC-1-001  
**Degrau da solução:** ajuste da solução existente — corrige o frontend Skip já publicado e estende o contrato de autorização, sem novo componente.

## Contexto e decisões fechadas

- **Estado atual:** a implementação Skip (`05_entregas/sv-digital-app`, commit `f989db7`) controla navegação pelo mapa `PODE` em `src/hooks/use-papel.tsx`. Três linhas divergem da matriz M1–M5: `lider_comercial` sem importação (M4 concede `C`), `admin` sem leitura de contatos sensíveis (M3 concede `R`) e a permissão `usuarios` sem tela de gestão de memberships (M1).
- **Estado desejado:** `PODE` reproduz exatamente M1–M5 e a Fase 2 possui contrato de autorização (M6) para os recursos novos antes de implementá-los.
- **Decisões já fechadas:** a matriz da SPEC-1-001 continua canônica; M6 é extensão, não substituição; ocultação na UI é primeira camada e a RLS continua negando server-side (CA-1-09).
- **Decisões de 29/10 (emenda):** a tela de importação é a completa que a SPEC-1-002 descreve (CSV → prévia com duplicidades e lacunas → executar), aberta a `lider_comercial` e `prospector`; os contatos sensíveis aparecem para `admin` no detalhe da conta, dentro da tela Contas, só para leitura, sem tela nova.
- **Bloqueios:** nenhum.

## Resultado observável

Cada papel vê exatamente as telas e ações que M1–M6 concedem; o `admin` convida, atribui papel e revoga membership pela interface, e a revogação remove o acesso na próxima requisição.

## Limites e dependências

- **Inclui:** correção do mapa `PODE`, tela de importação completa (CSV → prévia → executar) acessível a `lider_comercial` e `prospector`, contatos sensíveis para `admin` no detalhe da conta, tela de usuários/memberships e a matriz M6.
- **Fora de escopo:** novas políticas RLS dos recursos da Fase 2 (entregues nas SPECs 2-001 a 2-003), SSO e multi-organização.
- **Entradas:** matriz M1–M5 (SPEC-1-001), RPCs `my_role` e `revoke_member`, implementação `f989db7`.
- **Saídas:** `PODE` corrigido com teste de tabela, tela de usuários, matriz M6 publicada nesta SPEC.
- **Atores:** `admin` gerencia memberships; demais papéis validam a própria visão.
- **Superfícies:** `src/hooks/use-papel.tsx`, nova página de usuários no Skip, RPC `revoke_member` e função server-side de convite.
- **Risco e plano B:** convite por e-mail indisponível no ambiente; `admin` cria membership para usuário já cadastrado e o convite fica como pendência.
- **Rollback:** reverter o commit do `PODE`; a RLS permanece como barreira.

## Matriz M6 — recursos da Fase 2

Mesmas convenções da SPEC-1-001 (`C`/`R`/`U`/`D`/`—`, deny by default, toda escrita auditada).

| Recurso | admin | lider_comercial | prospector | vendedor | leitor |
|---|---|---|---|---|---|
| `research_jobs` (disparar/reprocessar pesquisa) | — | CRU | CRU | — | — |
| `evidences` de conta (registrar/corrigir) | R | CRU | CRU | R | R |
| `evidences` de contato (com telefone/e-mail) | R | CRU | CRU | — | — |
| Fila de pesquisa necessária | R | RU | RU | — | — |
| `score_runs` (executar) | — | C | C | — | — |
| Score e explicação (ler) | R | R | R | R | R |
| Recomendar conta para revisão | — | C | C | — | — |
| Decisão de revisão (aprovar/rejeitar/devolver conta) | — | CU | — | — | — |
| `cohorts` (criar/aprovar/encerrar) | — | CRU | R | — | — |
| Exportar coorte aprovada (CSV) | C | C | — | — | — |

**Regras transversais adicionais:**

| ID | Regra |
|---|---|
| PM-08 | Nenhuma conta muda para aprovada sem decisão humana de `lider_comercial` (RN-3 do escopo). |
| PM-09 | Agente ou job de pesquisa grava evidências com autoria `agente:<nome>`; nunca aprova, rejeita nem exporta. |
| PM-10 | `prospector` recomenda e devolve para pesquisa, mas não decide revisão nem aprova coorte. |

## Dados e integrações

| Origem/destino | Fonte de verdade | Campos/contrato | Autenticação/permissão | Timeout/retry/idempotência | Tratamento de erro |
|---|---|---|---|---|---|
| Skip → `my_role` | `memberships` | papel na organização ativa | sessão do usuário | sem retry; refetch manual | papel nulo exibe "Acesso não autorizado" |
| Skip → convite/atribuição | `memberships` + `audit_events` | e-mail, papel, organização | somente `admin` (M1) | membership única por usuário/organização | papel inválido rejeitado e auditado |
| Skip → `revoke_member` | `memberships` | organização, usuário | somente `admin` (M1) | revogar duas vezes não falha | erro exibido sem PII |

| Regra | Condição | Resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-201 | linha de `PODE` diverge de M1–M6 | teste de tabela falha | nenhuma | SPEC-1-001 |
| RN-202 | usuário sem `admin` abre tela de usuários | tela negada e RPC negada | nenhuma | M1 |
| RN-203 | membership revogada | próxima chamada a `my_role` retorna nulo | nenhuma | CA-1-13 |

## Fluxo e regras

1. Ethos escreve teste de tabela comparando `PODE` com M1–M6 e vê falhar nas três divergências.
2. Corrige `PODE`, libera a tela de importação para `lider_comercial` e a leitura de contatos sensíveis para `admin`.
3. Constrói a tela de usuários: listar memberships, convidar/atribuir papel e revogar.
4. O agente prova cada papel pelo teste de tabela e pelas consultas server-side com as fixtures; o cliente faz só o teste da SPEC (seção "Teste do cliente").

| Cenário | Condição | Resultado esperado | Recuperação |
|---|---|---|---|
| Principal | `lider_comercial` abre importação | tela disponível e importação executa | não aplicável |
| Limite | `admin` abre contato com telefone | dado visível, ação de edição indisponível (M3 `R`) | não aplicável |
| Falha | `prospector` abre tela de usuários | "Acesso não autorizado" e RPC negada | não aplicável |

## Instruções de execução para o Ethos

1. Ler SPEC-1-001 (M1–M5) e esta SPEC (M6).
2. Alterar somente `PODE`, rotas/telas de importação, contatos e usuários.
3. Não criar permissão sem linha na matriz.
4. Teste de tabela → correção → tela de importação → contatos no detalhe da conta → tela de usuários → regressão automática por papel.
5. Parar se alguma RPC existente contradizer a matriz.

## Checklist de execução

- [ ] Teste de tabela `PODE` × M1–M6 existe e passa.
- [ ] `lider_comercial` acessa importação; `admin` não acessa.
- [ ] `admin` lê contatos sensíveis; `vendedor` e `leitor` não.
- [ ] Tela de usuários lista, convida/atribui e revoga, apenas para `admin`.
- [ ] Toda ação da tela de usuários gera `audit_events`.

## Critérios de aceite

- [ ] **CA-2-13:** o mapa `PODE` é idêntico a M1–M6, provado por teste de tabela com uma linha por papel × recurso.
- [ ] **CA-2-14:** `lider_comercial` executa importação e `admin` lê contatos sensíveis; `vendedor` e `leitor` continuam sem contatos sensíveis.
- [ ] **CA-2-15:** `admin` convida, atribui papel e revoga membership pela interface; após revogar, o usuário perde acesso na próxima requisição e o evento fica auditado.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado | Evidência |
|---|---|---|---|---|
| RED | teste de tabela `PODE` × matriz | rodar teste antes da correção | falha nas três divergências | log RED |
| GREEN | mesmo teste + roteiro da tela de usuários | corrigir e construir tela | CA-2-13 a CA-2-15 passam | log e capturas |
| REFACTOR/REGRESSÃO | regressão automática por papel | rodar o teste de tabela e as provas server-side dos 5 papéis com as fixtures | nenhuma regressão de navegação | log da regressão |

**Fixtures:** cinco usuários de teste, um por papel, na organização da Fase 1.  
**Erros obrigatórios:** não-admin na tela de usuários, papel inválido no convite, revogação repetida.  
**Evidência:** log do teste de tabela e da regressão por papel. As fixtures são só do agente: o cliente não entra com usuário de teste.

## Handoff e operação

- **Como demonstrar:** logar com cada papel, mostrar telas visíveis e negadas; revogar um usuário e mostrar a perda de acesso.
- **Como operar:** `admin` gerencia memberships pela tela de usuários.
- **Como monitorar:** `audit_events` de convite, atribuição e revogação.
- **Pendência conhecida:** envio de e-mail de convite depende da configuração SMTP do Supabase.

## Teste do cliente (um só, no fim da SPEC)

Pedido quando a F2-T01 estiver no ar, em um roteiro só, feito pelo admin da SV com usuários reais:

1. Convidar um usuário, trocar o papel dele e revogar o acesso. O usuário revogado não entra mais.
2. Abrir a tela de importação logado como líder e ver a prévia de um CSV pequeno, sem executar.
3. Abrir uma conta e conferir que o admin vê telefone e e-mail do contato, sem botão de editar.

Aprovado quando os três passos funcionam (CA-2-13 a CA-2-15).

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F2-T01 | Alinhar permissões do Skip à matriz e criar tela de usuários | Ethos | SPEC-2-000 | CA-2-13 a CA-2-15 passam | RED → GREEN | log do teste de tabela e capturas por papel | implementação `f989db7` | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-10-23 | Fechamento da Fase 1 — revisão da implementação | SPEC-2-000, M6 e F2-T01 | Divergências do `PODE` com M1–M5 e recursos da Fase 2 sem dono por papel |
| 2026-10-29 | Pergunta do agente na análise da F2-T01 | SPEC-2-000 | Tela de importação completa e contatos sensíveis no detalhe da conta; teste do cliente por SPEC, com regressão por papel automática |
