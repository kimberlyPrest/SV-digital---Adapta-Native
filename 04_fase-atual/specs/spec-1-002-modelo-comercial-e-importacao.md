# SPEC-1-002 Modelo comercial ICP e importação da base

**Fase:** 1  
**Status:** planejada  
**Dono:** Liderança comercial  
**Origem no escopo:** seções 5, 8, 9 e Fase 1  
**Degrau da solução:** construção mínima — o modelo é específico ao processo da SV e precisa preservar proveniência, versões e estados.

## Contexto e decisões fechadas

- **Estado atual:** o Kommo possui funis diferentes por vendedor e o painel fornecido usa estágios que não equivalem necessariamente a oportunidade qualificada.
- **Estado desejado:** ICP, funil de pré-vendas, contas, contatos, coortes e próximos passos seguem um contrato único no Supabase.
- **Decisões já fechadas:** primeiro ICP em redes de mercados e varejistas multiunidade; dados sem fonte não são liberados para contato; nomes de clientes não são etapas.
- **Bloqueios:** arquivo exportável da base atual ou planilha equivalente para reconciliação.

## Resultado observável

A SV importa a base de referência, vê duplicidades e lacunas, cria a versão inicial do ICP e obtém registros ativos com responsável, estágio e próximo passo válidos.

## Limites e dependências

- **Inclui:** tabelas e regras de ICP, contas, contatos, coortes, estágios, atividades, preferências de contato, importação CSV e relatório de reconciliação.
- **Fora de escopo:** pesquisa automática, envio de mensagens e sincronização com CRM.
- **Entradas:** exportação da base, taxonomia aprovada e usuários da SPEC-1-001.
- **Saídas:** migrações, importador, mapeamento de colunas, relatório de erros e base reconciliada.
- **Atores:** liderança configura; prospector importa/revisa; vendedor lê handoffs futuros.
- **Permissões aplicáveis (fatia da matriz M2/M4 da SPEC-1-001):** publicar e desativar versão de ICP é exclusivo de `lider_comercial`; executar importação e revisar prévia cabem a `prospector` e `lider_comercial`; invalidar lote e liberar base para contato são exclusivos de `lider_comercial`; `vendedor` e `leitor` apenas leem registros comerciais, e `leitor` não vê dados de contato direto.
- **Superfícies:** tabelas Supabase, Edge Function `import-commercial-base` e telas de importação no Skip.
- **Risco e plano B:** exportação incompleta; manter lote como `importado_nao_reconciliado` e não liberar contato.
- **Rollback:** importação usa `batch_id`; lote pode ser invalidado sem apagar auditoria.

## Dados e integrações

| Origem/destino | Fonte de verdade | Campos/contrato | Autenticação/permissão | Timeout/retry/idempotência | Tratamento de erro |
|---|---|---|---|---|---|
| CSV → Supabase | arquivo fornecido + Supabase após aceite | conta, contato, estágio original, responsável, última ação, origem | prospector com permissão de importação | hash do arquivo + linha evita duplicação | linha inválida vai ao relatório |
| ICP → coorte | `icp_versions` | critérios JSON validados e versão imutável | líder cria; prospector lê | versão nova não altera coorte antiga | rejeitar critério sem tipo/unidade |

| Regra | Condição | Resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-121 | conta ativa | exige owner e próximo passo ou exceção | importado não reconciliado | Escopo 8.10 |
| RN-122 | CNPJ normalizado igual | sugerir mesma conta | grupo econômico pode manter contas distintas com justificativa | Escopo 7.5 |
| RN-123 | contato sem fonte/data | estado `pesquisa_necessaria` | dado fornecido diretamente pela pessoa registra essa origem | Escopo 5.3 |
| RN-124 | versão de ICP publicada | torna-se imutável | correção gera nova versão | Escopo 7.1 |
| RN-125 | usuário sem papel `lider_comercial` tenta publicar ICP, invalidar lote ou liberar base | operação negada e auditada | nenhuma | Matriz M2/M4 (SPEC-1-001) |

## Fluxo e regras

1. Liderança publica ICP v1.
2. Prospector envia CSV e mapeia colunas.
3. Sistema valida formatos, duplicidades e campos obrigatórios.
4. Usuário confirma a prévia.
5. Sistema grava lote e produz relatório de reconciliados, duplicados, incompletos e rejeitados.

| Cenário | Condição | Resultado esperado | Recuperação |
|---|---|---|---|
| Principal | CSV válido | registros importados uma vez | não aplicável |
| Limite | telefone em formatos diferentes | normalização aponta possível duplicidade | revisão humana |
| Falha | arquivo repetido | nenhuma duplicação; lote anterior é referenciado | cancelar nova execução |

## Instruções de execução para o Ethos

1. Ler escopo 5, 8 e 9 e SPEC-1-001.
2. Alterar somente modelo comercial e importador.
3. Não decidir pesos do ICP nem corrigir dados do cliente por inferência.
4. Criar testes → migrações → importador → relatório → demonstração.
5. Parar se a taxonomia ou o arquivo real contradizer o escopo.
6. Manter lote inválido isolado e reversível.

## Checklist de execução

- [ ] ICP v1 possui critérios, impedimentos, aprovador e vigência.
- [ ] Estados e motivos terminais usam enumeração controlada.
- [ ] Importador apresenta prévia antes de gravar.
- [ ] Duplicidades e linhas inválidas geram relatório.
- [ ] Repetição do lote é idempotente.
- [ ] Base importada não é liberada automaticamente para contato.

## Critérios de aceite

- [ ] **CA-1-05:** publicar ICP v1 não permite edição retroativa.
- [ ] **CA-1-06:** importar duas vezes o mesmo arquivo não duplica conta, contato ou atividade.
- [ ] **CA-1-07:** todo ativo reconciliado possui owner e próximo passo ou exceção.
- [ ] **CA-1-08:** relatório separa importados, duplicados, incompletos e rejeitados.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado | Evidência |
|---|---|---|---|---|
| RED | importar fixture com duplicados e campos ausentes | executar teste do importador | falha até existirem validações | log RED |
| GREEN | importar fixture válida e repeti-la | teste Edge Function + `supabase test db` | CA-1-05 a CA-1-08 passam | relatório JSON e log |
| REFACTOR/REGRESSÃO | formatos de telefone/CNPJ e versão de ICP | suíte de bordas | normalização sem fusão indevida | relatório de regressão |

**Fixtures:** base mínima com 12 contas, duplicatas, CNPJ ausente, contato sem fonte e etapas legadas.  
**Erros obrigatórios:** CSV inválido, coluna ausente, lote repetido e usuário sem permissão (prospector tentando invalidar lote ou publicar ICP — RN-125).  
**Evidência:** relatório de importação e consultas de consistência.

## Handoff e operação

- **Como demonstrar:** publicar ICP, importar fixture, revisar relatório e invalidar o lote.
- **Como operar:** prospector importa; liderança publica versões.
- **Como monitorar:** duplicidade, cobertura de fonte, owner e próximo passo.
- **Pendência conhecida:** mapeamento exato das colunas depende do export real.

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F1-T04 | Definir fixtures e testes RED do modelo comercial | Ethos | SPEC-1-002 | RED reproduz duplicidade e lacunas | RED | log e fixture | SPEC-1-001 | ☐ |
| F1-T05 | Implementar ICP funil entidades e importação idempotente | Ethos | SPEC-1-002 | CA-1-05 a CA-1-08 | GREEN | migrações e relatório | F1-T04 | ☐ |
| F1-T06 | Reconciliar a fotografia atual e validar relatório | Champion SV | SPEC-1-002 | base classificada sem liberação indevida | REGRESSÃO | relatório assinado | F1-T05 e export real | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| 2026-09-28 | Consultora (Kim) — lacuna detectada na revisão | Fatia de permissões M2/M4 + RN-125 | Publicação de ICP, invalidação de lote e liberação de base precisavam de dono explícito por papel na SPEC |
