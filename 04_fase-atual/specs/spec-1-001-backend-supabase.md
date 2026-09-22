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
- **Atores e permissões mínimas:** `admin`, `lider_comercial`, `prospector`, `vendedor`, `leitor`; service role somente em funções server-side.
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
| RN-102 | ação administrativa ou em lote | exigir papel `admin` ou `lider_comercial` conforme matriz | nenhuma elevação pelo cliente | Escopo 7.13 |
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

## Instruções de execução para o Ethos

1. **Ler antes de alterar:** escopo definitivo, esta SPEC e matriz de papéis.
2. **Alterar somente:** projeto Supabase e configuração de conexão do Skip.
3. **Não alterar:** regras comerciais, canal WhatsApp ou CRM.
4. **Executar nesta ordem:** testes RED de isolamento → migrações → RLS → auditoria → filas → testes GREEN.
5. **Parar e pedir validação quando:** não houver projeto, administrador ou política de ambientes.
6. **Estado válido ao parar:** migrações aplicáveis do zero e nenhum acesso amplo temporário.

## Checklist de execução

- [ ] Ambientes local e homologação identificados.
- [ ] Migrações criam organizações, perfis, memberships, auditoria e eventos de integração.
- [ ] RLS cobre todas as tabelas expostas.
- [ ] Service role não aparece no frontend.
- [ ] Filas privadas existem e não são acessíveis a usuários comuns.
- [ ] Testes de isolamento, papel e auditoria passam.

## Critérios de aceite

- [ ] **CA-1-01:** um usuário da organização A não lê nem altera dados da organização B.
- [ ] **CA-1-02:** cada ação crítica testada gera evento de auditoria com ator e timestamp.
- [ ] **CA-1-03:** nenhuma credencial privilegiada existe no bundle ou nas configurações públicas do Skip.
- [ ] **CA-1-04:** `supabase db reset` e os testes reproduzem o schema em ambiente limpo.

## TDD da SPEC

| Etapa | Prova | Comando/ação | Resultado esperado | Evidência |
|---|---|---|---|---|
| RED | usuário A acessa fixture da B antes das políticas | `supabase test db` | teste de isolamento falha | log em `evidencias/fase-1/spec-1-001-red.txt` |
| GREEN | RLS, papéis e auditoria aplicados | `supabase db reset && supabase test db` | CA-1-01 a CA-1-04 passam | log GREEN |
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
| | | | |
