# SPEC-2-001 Pesquisa, enriquecimento e proveniência

**Fase:** 2  
**Status:** planejada  
**Dono:** Profissional de prospecção  
**Origem no escopo:** seções 4.3, 5, 7.2, 7.3, 10.2 e Fase 2  
**Degrau da solução:** construção mínima com conector substituível — jobs assíncronos no Supabase gravam evidências com fonte; a fonte de dados é plugável e o cadastro manual com evidência é o caminho garantido.

## Contexto e decisões fechadas

- **Estado atual:** a Fase 1 entregou contas e contatos importados com origem do lote, sem sinais de aderência nem evidências por campo.
- **Estado desejado:** cada conta do ICP prioritário tem porte, região, unidades, sinais (expansão, inauguração, reforma) e contatos por papel, cada dado com fonte, data e confiança; o que faltar ou conflitar vai para "pesquisa necessária".
- **Decisões já fechadas:** a IA nunca completa dado por inferência (escopo 5.3); fornecedor atual não é requisito; nenhum conector é considerado disponível antes de teste com credencial real (10.2); LinkedIn sem automação não autorizada.
- **Bloqueios:** definição pela SV de qual fonte contratada de enriquecimento será usada; até lá, operam fontes públicas autorizadas e cadastro manual.

## Resultado observável

O prospector dispara a pesquisa de um recorte do ICP, acompanha os jobs e vê em cada conta os sinais e contatos com a evidência de origem; contas incompletas aparecem na fila de pesquisa necessária com o motivo.

## Limites e dependências

- **Inclui:** tabelas `research_jobs` e `evidences`, estados de pesquisa da conta, Edge Function `research-account` com fila, adaptador de fonte, cadastro manual de evidência, fila de pesquisa necessária e detalhe da conta no Skip.
- **Fora de escopo:** pontuação (SPEC-2-002), coortes (SPEC-2-003), contato externo e agentes autônomos de loop (Fase 4).
- **Entradas:** ICP v1 e contas da SPEC-1-002, matriz M6 (SPEC-2-000), credenciais de fontes em secrets server-side.
- **Saídas:** evidências persistidas, contas com estado de pesquisa, fila de pesquisa necessária.
- **Atores:** prospector e liderança disparam e corrigem; vendedor e leitor leem evidências de conta (M6).
- **Superfícies:** Supabase (tabelas, fila, Edge Function), telas Skip "Pesquisa" e "Detalhe da conta".
- **Risco e plano B:** fonte indisponível, bloqueada ou com custo não previsto; job falha visível e o prospector registra evidência manual com URL.
- **Rollback:** evidências são versionadas por `job_id`; um job pode ser invalidado sem apagar auditoria.

## Dados e integrações

| Origem/destino | Fonte de verdade | Campos/contrato | Autenticação/permissão | Timeout/retry/idempotência | Tratamento de erro |
|---|---|---|---|---|---|
| Fonte pública (site, base CNPJ) → `evidences` | fonte externa na data da coleta | conta, campo, valor, URL/referência, trecho, data de coleta, autor (`usuario` ou `agente:<nome>`), confiança | job server-side; credencial em secret | timeout 20 s, 3 tentativas com backoff; chave `account_id + campo + hash(fonte+valor)` | erro sanitizado no job; conta vai para pesquisa necessária |
| Fonte contratada → `evidences` | idem | idem | secret por conector | idem | conector desligado até teste real aprovado |
| Cadastro manual → `evidences` | usuário autor | idem, URL obrigatória | `prospector` / `lider_comercial` (M6) | mesma chave de idempotência | sem URL não salva como verificado |

| Regra | Condição | Resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-211 | dado sem fonte ou sem data | não é exibido como verificado | dado fornecido pela própria conta registra essa origem | Escopo 5.3, 8.2 |
| RN-212 | duas evidências com valores diferentes para o mesmo campo | conta marcada `conflito` e enviada à pesquisa necessária | evidência mais recente da mesma fonte substitui a anterior | Escopo 7.3 |
| RN-213 | campo obrigatório do ICP ausente | estado `pesquisa_necessaria` com motivo | nenhuma | Escopo 5.3 |
| RN-214 | contato sem papel, canal ou data de verificação | contato não liberado | nenhuma | Escopo 7.3 |
| RN-215 | job repetido para a mesma conta e fonte | nenhuma evidência duplicada | nenhuma | Escopo 14.2 |

## Fluxo e regras

1. Prospector seleciona um recorte do ICP e dispara a pesquisa.
2. Sistema cria um `research_job` por conta e enfileira.
3. Worker consulta a fonte, grava evidências e atualiza o estado da conta.
4. Conflitos e lacunas vão para a fila de pesquisa necessária.
5. Prospector resolve manualmente com evidência e devolve a conta para pronta.

| Cenário | Condição | Resultado esperado | Recuperação |
|---|---|---|---|
| Principal | fonte responde com unidades e site | evidências gravadas e conta `pesquisada` | não aplicável |
| Limite | duas fontes discordam do número de unidades | conta `conflito` com as duas evidências visíveis | prospector escolhe e registra motivo |
| Falha | fonte em timeout | job `falhou` com erro sanitizado, conta em pesquisa necessária | reprocessar sem duplicar |

## Instruções de execução para o Ethos

1. Ler escopo 4.3, 5, 7.2, 7.3, 10.2, SPEC-1-002 e SPEC-2-000 (M6).
2. Alterar somente pesquisa, evidências e telas de pesquisa/detalhe.
3. Não escolher fonte contratada nem ligar conector sem teste com credencial real aprovado pela SV.
4. Testes → migrações e RLS (M6) → fila e Edge Function → telas → demonstração.
5. Parar se a fonte exigir automação não autorizada.
6. Nunca gravar dado inferido sem evidência.

## Checklist de execução

- [ ] `research_jobs` e `evidences` com RLS conforme M6.
- [ ] Adaptador de fonte substituível com contrato único.
- [ ] Idempotência por chave de evidência.
- [ ] Fila de pesquisa necessária com motivo.
- [ ] Evidência de contato com telefone/e-mail invisível para `vendedor` e `leitor`.
- [ ] Cadastro manual exige URL ou referência.

## Critérios de aceite

- [ ] **CA-2-01:** toda evidência exibe fonte, URL ou referência, data de coleta, autor e confiança; dado sem fonte não aparece como verificado.
- [ ] **CA-2-02:** conta com campo obrigatório ausente ou conflitante entra em pesquisa necessária com motivo legível.
- [ ] **CA-2-03:** contatos exibem papel, canal, fonte e data de verificação; `vendedor` e `leitor` não veem telefone nem e-mail.
- [ ] **CA-2-04:** reprocessar um job falho ou repetido não duplica evidências e a falha fica visível com erro sanitizado.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado | Evidência |
|---|---|---|---|---|
| RED | fixture com fonte simulada (sucesso, conflito, timeout) | rodar testes do worker e de RLS | falham sem tabelas e regras | log RED |
| GREEN | mesma fixture + repetição do job | testes Edge Function + `supabase test db` | CA-2-01 a CA-2-04 passam | log e consultas |
| REFACTOR/REGRESSÃO | 20 contas reais do ICP com fonte autorizada | pesquisa em homologação | evidências rastreáveis, sem duplicação | relatório de pesquisa |

**Fixtures:** 10 contas com respostas simuladas da fonte: completa, sem unidades, conflito de unidades, timeout e contato sem data.  
**Erros obrigatórios:** timeout, resposta inválida, job repetido e `vendedor` tentando ler contato sensível.  
**Evidência:** log dos testes e relatório das 20 contas reais.

## Handoff e operação

- **Como demonstrar:** disparar pesquisa de 5 contas, abrir detalhe com evidências, resolver um conflito na fila.
- **Como operar:** prospector dispara e resolve a fila diariamente.
- **Como monitorar:** jobs falhos, tamanho da fila de pesquisa necessária, cobertura de fonte por campo.
- **Pendência conhecida:** fonte contratada depende de decisão e credencial da SV.

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F2-T02 | Criar fixtures e testes RED de pesquisa e proveniência | Ethos | SPEC-2-001 | RED falha em evidência, conflito e idempotência | RED | log RED e fixture | F2-T01 | ☐ |
| F2-T03 | Implementar jobs evidências fila de pesquisa e telas | Ethos | SPEC-2-001 | CA-2-01 a CA-2-04 passam | GREEN | migrações, log e capturas | F2-T02 | ☐ |
| F2-T04 | Pesquisar 20 contas reais do ICP em homologação | Prospector SV | SPEC-2-001 | 20 contas com evidências ou em pesquisa necessária | REGRESSÃO | relatório de pesquisa | F2-T03 e fonte autorizada | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | — | — |
