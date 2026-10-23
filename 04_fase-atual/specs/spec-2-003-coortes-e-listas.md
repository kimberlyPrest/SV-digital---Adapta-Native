# SPEC-2-003 Coortes, deduplicação e aprovação humana da lista

**Fase:** 2  
**Status:** planejada  
**Dono:** Liderança comercial  
**Origem no escopo:** seções 7.5, 7.7, 8.1, 8.6, 9 e Fase 2  
**Degrau da solução:** construção mínima — revisão e coorte são regras do processo da SV; reutiliza contas, evidências e pontuação existentes.

## Contexto e decisões fechadas

- **Estado atual:** contas pesquisadas (SPEC-2-001) e pontuadas (SPEC-2-002), sem lista revisada nem coorte.
- **Estado desejado:** a liderança revisa contas recomendadas, aprova, rejeita ou devolve cada uma com motivo, e aprova a primeira coorte congelada na versão do ICP, sem duplicidades.
- **Decisões já fechadas:** nenhuma conta é aprovada apenas pela pontuação; a mesma conta não participa de duas coortes ativas (8.6); toda conta contatada pertence a coorte e versão de ICP (8.1); primeira coorte em redes de mercados e varejo multiunidade no RS e SC.
- **Bloqueios:** nenhum além das pendências das SPECs 2-001 e 2-002.

## Resultado observável

A liderança filtra a lista, vê duplicidades sinalizadas, decide conta a conta com motivo e aprova a primeira coorte, que fica congelada e exportável em CSV para preparação da abordagem na Fase 3.

## Limites e dependências

- **Inclui:** tabelas `cohorts`, `cohort_members` e `account_reviews`; filtros salvos; detecção de duplicidade; recomendação pelo prospector; decisão pela liderança; congelamento e exportação CSV.
- **Fora de escopo:** mensagens, cadência e envio (Fase 3); aprovação de lote de envio (7.7 na parte de cadência fica na Fase 3).
- **Entradas:** contas, evidências e `score_runs`; matriz M6.
- **Saídas:** coorte aprovada, decisões auditadas, CSV da coorte.
- **Atores:** prospector recomenda e devolve para pesquisa; liderança decide e aprova coorte; admin exporta (M6).
- **Superfícies:** telas Skip "Lista do ICP", "Revisão" e "Coortes"; função server-side de exportação.
- **Risco e plano B:** duplicidade não detectada por grupo econômico; liderança marca manualmente e a conta é removida da coorte antes da aprovação.
- **Rollback:** coorte aprovada pode ser encerrada; decisões e versão congelada permanecem no histórico.

## Dados e integrações

| Origem/destino | Fonte de verdade | Campos/contrato | Autenticação/permissão | Timeout/retry/idempotência | Tratamento de erro |
|---|---|---|---|---|---|
| Revisão → `account_reviews` | decisão humana | conta, decisão (`aprovada`/`rejeitada`/`devolvida`), motivo obrigatório, revisor, `score_run_id` visto, data | decisão só `lider_comercial`; recomendação `prospector`/`lider_comercial` (M6) | uma decisão vigente por conta e coorte | sem motivo não salva |
| Coorte → `cohorts` | `cohorts` | objetivo, versão do ICP, período, volume, responsáveis, canais previstos, status, critérios de encerramento | `lider_comercial` (M6) | aprovação congela membros e versão | conta em outra coorte ativa bloqueia aprovação |
| Coorte → CSV | coorte aprovada | conta, CNPJ, região, unidades, nota, motivo, contato por papel sem telefone/e-mail para quem não pode lê-los | `admin` / `lider_comercial` (M6) | exportação registrada em auditoria | erro exibido; nada parcial é entregue |

| Regra | Condição | Resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-231 | mesmo CNPJ, mesmo domínio ou nome normalizado + cidade | duplicidade sinalizada antes da revisão | grupo econômico mantém contas distintas com justificativa (RN-122) | Escopo 7.5 |
| RN-232 | conta já em coorte ativa | não pode entrar em outra coorte ativa | nenhuma | Escopo 8.6 |
| RN-233 | decisão `devolvida` | conta volta à pesquisa necessária com o motivo | nenhuma | Escopo Fase 2 |
| RN-234 | coorte aprovada | membros e versão do ICP congelados | encerramento com motivo | Escopo 7.1, 8.15 |
| RN-235 | coorte sem nenhuma conta aprovada ou com duplicidade aberta | aprovação bloqueada | nenhuma | Escopo Fase 2 |

## Fluxo e regras

1. Prospector filtra a lista (segmento, região, porte, sinal, nota, responsável) e recomenda contas.
2. Sistema sinaliza duplicidades e contas em outra coorte ativa.
3. Liderança abre a revisão, vê evidências e nota e decide cada conta com motivo.
4. Liderança cria a coorte com objetivo, volume e responsáveis e aprova.
5. Sistema congela a coorte e libera a exportação CSV.

| Cenário | Condição | Resultado esperado | Recuperação |
|---|---|---|---|
| Principal | 30 contas recomendadas sem duplicidade | coorte aprovada e exportada | não aplicável |
| Limite | duas contas com o mesmo CNPJ | sinalizadas; liderança mantém uma ou justifica as duas | revisão manual |
| Falha | conta já em coorte ativa | aprovação bloqueada com o nome da coorte conflitante | remover a conta ou encerrar a outra coorte |

## Instruções de execução para o Ethos

1. Ler escopo 7.5, 7.7, 8 e 9 e SPECs 2-000 a 2-002.
2. Alterar somente revisão, coortes, filtros e exportação.
3. Não aprovar contas por regra automática nem preencher motivo.
4. Testes → migrações e RLS (M6) → telas de revisão e coorte → exportação → demonstração.
5. Parar se a liderança pedir aprovação sem motivo.
6. Exportação respeita M3/M6 para dados de contato.

## Checklist de execução

- [ ] Filtros por segmento, região, porte, sinal, nota e responsável, salvos por usuário.
- [ ] Duplicidade sinalizada antes da revisão.
- [ ] Decisão exige motivo e é auditada.
- [ ] Conta não entra em duas coortes ativas.
- [ ] Coorte aprovada congelada e exportável.
- [ ] `prospector` não consegue decidir nem aprovar coorte.

## Critérios de aceite

- [ ] **CA-2-09:** a lista filtra por segmento, região, porte, sinal, nota e responsável, e o filtro salvo reabre igual.
- [ ] **CA-2-10:** duplicidades são sinalizadas antes da aprovação e uma conta não entra em duas coortes ativas.
- [ ] **CA-2-11:** a liderança aprova, rejeita ou devolve cada conta com motivo obrigatório e auditado; devolvida volta à pesquisa necessária; `prospector` tentando decidir é negado.
- [ ] **CA-2-12:** a primeira coorte real de redes de mercados ou varejo multiunidade é aprovada, congelada na versão do ICP e exportada em CSV.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado | Evidência |
|---|---|---|---|---|
| RED | fixture com duplicados, conta em coorte ativa e decisões sem motivo | rodar testes de revisão e coorte | falham sem regras | log RED |
| GREEN | mesma fixture + aprovação e exportação | testes + `supabase test db` | CA-2-09 a CA-2-11 passam | log e CSV |
| REFACTOR/REGRESSÃO | primeira coorte real com a liderança | revisão e aprovação em homologação | CA-2-12 aprovado sem bypass | aceite e CSV da coorte |

**Fixtures:** 15 contas pontuadas com 2 duplicadas por CNPJ, 1 por domínio, 1 em coorte ativa e 1 impedida.  
**Erros obrigatórios:** decisão sem motivo, aprovação com duplicidade aberta, `prospector` decidindo, exportação por `vendedor`.  
**Evidência:** log dos testes, CSV e registro de aceite da liderança.

## Handoff e operação

- **Como demonstrar:** filtrar, resolver uma duplicidade, decidir três contas (aprovar, rejeitar, devolver), aprovar e exportar a coorte.
- **Como operar:** prospector recomenda semanalmente; liderança revisa e aprova coortes.
- **Como monitorar:** contas aguardando revisão, duplicidades abertas, coortes ativas e volume.
- **Pendência conhecida:** canais previstos da coorte são apenas declarativos até a Fase 3.

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F2-T08 | Criar fixtures e testes RED de revisão e coortes | Ethos | SPEC-2-003 | RED falha em duplicidade, motivo e coorte concorrente | RED | log RED e fixture | F2-T06 | ☐ |
| F2-T09 | Implementar lista revisão coortes e exportação | Ethos | SPEC-2-003 | CA-2-09 a CA-2-11 passam | GREEN | migrações, log, capturas e CSV | F2-T08 | ☐ |
| F2-T10 | Aprovar a primeira coorte real com a liderança | Champion SV | SPEC-2-003 | CA-2-12 aprovado sem bypass | REGRESSÃO | aceite e CSV da coorte | F2-T09 e F2-T07 | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | — | — |
