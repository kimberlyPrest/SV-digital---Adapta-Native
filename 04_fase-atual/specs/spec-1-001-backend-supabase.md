# SPEC-1-001 Backend Supabase seguro e auditável

**Fase:** 1  
**Status:** planejada  
**Dono:** Administrador técnico  
**Origem no escopo:** seções 4, 9, 10, 14 e Fase 1  
**Degrau da solução:** recurso nativo da plataforma — Supabase fornece Postgres, Auth, RLS, Edge Functions, Queues e secrets no mesmo backend.

## Contexto e decisões fechadas

- **Estado atual:** não existe backend próprio para o sistema de prospecção nem fonte de verdade para conversas do WhatsApp.
- **Estado desejado:** existe um projeto Supabase versionado, com isolamento por organização, papéis, auditoria, filas e ambientes separados.
- **Decisões já fechadas:** Skip é o frontend; Supabase é o backend; credenciais privilegiadas ficam apenas server-side; WhatsApp e agentes serão integrados nas fases seguintes.
- **Bloqueios:** criação do projeto e definição das contas administrativas da SV.

## Resultado observável

Um usuário autenticado acessa somente os dados e ações permitidos ao seu papel; uma tentativa de cruzar organização ou usar ação administrativa pelo frontend é rejeitada e auditada.

## Limites e dependências

- **Inclui:** estrutura do projeto, migrações, Auth, organizações, perfis, memberships, RLS, auditoria, secrets, filas vazias e ambientes local/homologação.
- **Fora de escopo:** regras de ICP, WhatsApp ativo, modelos de IA, Kommo e Holdprint.
- **Entradas e pré-condições:** projeto Supabase criado; administrador nomeado; Supabase CLI disponível.
- **Saídas/artefatos:** `supabase/config.toml`, migrações, seeds de teste, políticas RLS, testes pgTAP e inventário de secrets.
- **Dependências e responsáveis:** administrador técnico fornece projeto; Ethos implementa; Champion valida papéis.
- **Atores e permissões mínimas:** `admin`, `lider_comercial`, `prospector`, `vendedor`, `leitor`, definidos na seção **Matriz de permissões por papel** desta SPEC; service role somente em funções server-side.
- **Superfícies afetadas:** `supabase/migrations/`, `supabase/tests/database/`, `supabase/functions/` e variáveis do projeto.
- **Risco e plano B:** indisponibilidade do projeto gerenciado; desenvolver localmente e manter migrações reproduzíveis.
- **Rollback:** reverter a última migração em homologação ou restaurar backup antes de promover; nunca apagar produção para corrigir schema.

## Dados e integrações

| Origem/destino | Fonte de verdade | Campos/contrato | Autenticação/permissão | Timeout/retry/idempotência | Tratamento de erro |
|---|---|---|---|---|---|
| Skip → Supabase | Supabase Auth e Postgres | JWT do usuário e `organization_id` | anon key + RLS; nunca service role | operações mutáveis usam UUID e constraint | erro sanitizado no frontend; detalhe no log server-side |
| Edge Functions → Postgres | Supabase Postgres | service role em secret | função server-side | chave de idempotência por operação externa | registrar em `integration_events` |
| Workers → Queues | Supabase Queues | JSON com `event_id`, tipo e referência | service role | visibility timeout e número máximo de tentativas | arquivar ou enviar para fila de falhas |

| Regra de negócio | Condição | Ação/resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-101 | registro pertencente a uma organização | somente membros ativos da organização podem lê-lo | service role em função autorizada | Escopo 14.1 |
| RN-102 | ação administrativa ou em lote | exigir papel `admin` ou `lider_comercial` conforme a seção Matriz de permissões por papel | nenhuma elevação pelo cliente | Escopo 7.13 |
| RN-103 | alteração crítica | gravar ator, ação, objeto, antes/depois permitido e timestamp | payload sensível deve ser redigido | Escopo 9 |
| RN-104 | secret de integração | armazenar em Supabase Secrets | nunca retornar ao Skip | Escopo 8 e 10.3 |

## Fluxo e regras

1. Usuário autentica no Supabase.
2. O JWT identifica o usuário; a membership ativa determina organização e papel.
3. RLS filtra leitura e escrita.
4. Ações críticas passam por função ou trigger de auditoria.
5. Jobs assíncronos entram em filas privadas e são consumidos apenas server-side.

| Cenário | Dado/condição | Resultado esperado | Caminho de erro/recuperação |
|---|---|---|---|
| Principal | prospector ativo na organização A | acessa somente registros operacionais da A | não aplicável |
| Limite | vendedor tenta alterar regra de ICP | operação negada e tentativa auditada | líder executa a mudança |
| Falha | usuário da organização A consulta UUID da B | zero linhas ou 403 sem vazamento | revisar RLS antes de continuar |

## Matriz de permissões por papel

Esta matriz é o contrato canônico de autorização da Fase 1. Toda política RLS, toda verificação de papel em Edge Function e todo controle de navegação do Skip **devem implementar exatamente esta tabela** — nenhuma permissão pode existir no código sem linha correspondente aqui, e nenhuma linha daqui pode ser relaxada sem emenda a esta SPEC.

**Convenções:** `C` = cria, `R` = lê, `U` = edita, `D` = remove/arquiva, `—` = sem acesso. Toda escrita gera evento de auditoria (RN-103). Papel é atribuído por membership ativa; membership revogada remove o acesso imediatamente (CA-1-13).

### M1. Usuários, papéis e memberships

| Recurso | admin | lider_comercial | prospector | vendedor | leitor |
|---|---|---|---|---|---|
| `organizations` (configuração) | CRUD | R | R | R | R |
| `profiles` (próprio) | RU | RU | RU | RU | RU |
| `profiles` (de outros) | CRUD | R | — | — | — |
| `memberships` (convidar/atribuir papel/revogar) | CRUD | R | — | — | — |
| `audit_events` | R | R | — | — | — |

### M2. ICP e regras comerciais

| Recurso | admin | lider_comercial | prospector | vendedor | leitor |
|---|---|---|---|---|---|
| `icp_versions` (criar/publicar) | — | CR | — | — | — |
| `icp_versions` (ler) | R | R | R | R | R |
| `icp_versions` (desativar versão publicada) | — | U | — | — | — |
| `funnel_stages` e taxonomia de estados | RU | CRUD | R | R | R |
| `cadence_policies` (fases futuras) | RU | CRUD | R | R | — |

### M3. Contas, contatos e coortes

| Recurso | admin | lider_comercial | prospector | vendedor | leitor |
|---|---|---|---|---|---|
| `accounts` / `contacts` (criar/editar) | U | CRU | CRU | — | — |
| `accounts` / `contacts` (ler) | R | R | R | R | R |
| `contacts` (dados de contato sensíveis: telefone/e-mail) | R | R | R | — | — |
| `cohortes` (criar/aprovar) | — | CRU | R | — | — |
| `cohortes` (ler) | R | R | R | R | R |
| `activities` (histórico de interações) | RU | CRU | CRU | R | R |

### M4. Importação e reconciliação

| Recurso | admin | lider_comercial | prospector | vendedor | leitor |
|---|---|---|---|---|---|
| Executar importação CSV (`import-commercial-base`) | — | C | C | — | — |
| Revisar/confirmar prévia do lote | — | U | U | — | — |
| Invalidar lote | — | U | — | — | — |
| Relatório de reconciliação | R | R | R | — | — |
| Liberar base para contato | — | U | — | — | — |

### M5. Painel, filas e operação

| Recurso | admin | lider_comercial | prospector | vendedor | leitor |
|---|---|---|---|---|---|
| Painel inicial e indicadores | R | R | R | R | R |
| Fila de correção de pendências | R | RU | RU | — | — |
| Exportações de segurança | C | R | — | — | — |
| Secrets e configuração de conectores | CRUD | — | — | — | — |
| Filas (Queues) | — | — | — | — | — |

**Regras transversais da matriz:**

| ID | Regra |
|---|---|
| PM-01 | Nenhum papel humano usa service role; ela existe apenas em Edge Functions e workers server-side. |
| PM-02 | `leitor` nunca acessa dados de contato direto (telefone/e-mail) nem fila de correção; vê apenas painéis e registros comerciais sem PII de contato. |
| PM-03 | `vendedor` não altera ICP, taxonomia, coortes nem importa base; na Fase 1 ele apenas lê handoffs futuros. |
| PM-04 | `prospector` não publica nem desativa versão de ICP e não invalida lote de importação. |
| PM-05 | `admin` é o único papel que gerencia usuários, memberships, secrets e exportações; não publica ICP (decisão comercial) nem importa base. |
| PM-06 | Toda concessão fora desta matriz é negada por padrão e registrada em auditoria (deny by default). |
| PM-07 | Papel não é global: a mesma pessoa pode ter papéis diferentes em organizações diferentes, e a RLS avalia sempre a membership ativa da organização do registro. |

**Prova negativa obrigatória (por papel):** para cada uma das 5 colunas, executar no mínimo uma tentativa de ação proibida pela matriz (ex.: prospector publicando ICP, vendedor importando base, leitor abrindo contato com telefone, admin publicando ICP) e registrar a negação com evento de auditoria. A suíte de testes da SPEC-1-001 deve materializar cada uma dessas tentativas.

## Instruções de execução para o Ethos

1. **Ler antes de alterar:** escopo definitivo, esta SPEC e a seção Matriz de permissões por papel (M1–M5).
2. **Alterar somente:** projeto Supabase e configuração de conexão do Skip.
3. **Não alterar:** regras comerciais, canal WhatsApp ou CRM.
4. **Executar nesta ordem:** testes RED de isolamento e de matriz de permissões → migrações → RLS → auditoria → filas → testes GREEN.
5. **Parar e pedir validação quando:** não houver projeto, administrador ou política de ambientes.
6. **Estado válido ao parar:** migrações aplicáveis do zero e nenhum acesso amplo temporário.

## Checklist de execução

- [ ] Ambientes local e homologação identificados.
- [ ] Migrações criam organizações, perfis, memberships, auditoria e eventos de integração.
- [ ] RLS cobre todas as tabelas expostas.
- [ ] Políticas RLS implementam a matriz M1–M5 sem concessão fora dela.
- [ ] Service role não aparece no frontend.
- [ ] Filas privadas existem e não são acessíveis a usuários comuns.
- [ ] Testes de isolamento, papel e auditoria passam.

## Critérios de aceite

- [ ] **CA-1-01:** um usuário da organização A não lê nem altera dados da organização B.
- [ ] **CA-1-02:** cada ação crítica testada gera evento de auditoria com ator e timestamp.
- [ ] **CA-1-03:** nenhuma credencial privilegiada existe no bundle ou nas configurações públicas do Skip.
- [ ] **CA-1-04:** `supabase db reset` e os testes reproduzem o schema em ambiente limpo.
- [ ] **CA-1-13:** a matriz de permissões M1–M5 está implementada e provada por teste: cada papel executa as ações permitidas e **pelo menos uma tentativa proibida por papel é negada e auditada** (prova negativa), incluindo revogação de membership removendo acesso imediatamente.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | usuário A acessa fixture da B antes das políticas | `supabase test db` | teste de isolamento falha | log em `evidencias/fase-1/spec-1-001-red.txt` |
| GREEN | RLS, papéis e auditoria aplicados | `supabase db reset && supabase test db` | CA-1-01 a CA-1-04 e CA-1-13 passam | log GREEN |
| REFACTOR/REGRESSÃO | testar papel inválido, membership revogada e fila privada | repetir suíte completa | acesso negado sem quebrar caminho válido | relatório da suíte |

**Dados/fixtures:** duas organizações, cinco papéis, um usuário revogado e registros cruzados.  
**Caminhos de erro obrigatórios:** JWT ausente, membership revogada, papel insuficiente e UUID de outra organização.  
**Evidência exigida:** migrações, saída da suíte e captura da matriz de permissões aplicada.

## Handoff e operação

- **Como demonstrar:** entrar com dois usuários e provar isolamento e auditoria.
- **Como operar depois:** administrador cria membros e revoga acessos; mudanças de schema usam migração.
- **Como monitorar:** logs de Auth, erros de RLS e eventos críticos.
- **Pendência conhecida:** nenhuma após definição do administrador.

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F1-T01 | Criar testes RED de isolamento e papéis | Ethos | SPEC-1-001 | testes falham antes da RLS | RED | log RED | projeto local | ☐ |
| F1-T02 | Implementar schema base Auth RLS auditoria e filas | Ethos | SPEC-1-001 | CA-1-01 a CA-1-04 | GREEN | migrações e log | F1-T01 | ☐ |
| F1-T03 | Provar revogação secrets e recuperação do schema | Administrador técnico | SPEC-1-001 | regressão completa aprovada | REGRESSÃO | relatório e inventário | F1-T02 | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-09-28 | Consultora (Kim) — lacuna detectada na revisão | Matriz de permissões M1–M5 + CA-1-13 | As SPECs citavam papéis e "conforme matriz" (RN-102) sem definir a matriz; CA-1-09 não era testável sem o contrato de autorização por papel |
