# SPEC-2-002 Pontuação explicável de aderência

**Fase:** 2  
**Status:** planejada  
**Dono:** Liderança comercial  
**Origem no escopo:** seções 5.2, 7.1, 7.4, 8.1, 8.3, 8.15 e Fase 2  
**Degrau da solução:** regra determinística sobre evidências — o número vem dos pesos da versão do ICP aplicados a sinais com evidência; a IA pode sugerir sinais e redigir a justificativa, mas não define a nota.

## Contexto e decisões fechadas

- **Estado atual:** ICP versionado (SPEC-1-002) e evidências por conta (SPEC-2-001), sem priorização.
- **Estado desejado:** cada conta tem pontuação de aderência e prioridade reproduzível, com componentes, pesos e evidências visíveis, vinculada à versão do ICP.
- **Decisões já fechadas:** pontuação é recomendação, não decisão (8.3); aprovação final é humana (7.4); mudanças de critério valem para novas execuções e preservam o histórico (8.15).
- **Bloqueios:** pesos e critérios mínimos do ICP v1 definidos pela liderança — o Ethos não decide pesos.

## Resultado observável

A liderança abre a lista do ICP e vê, para cada conta, a nota, os componentes que somaram, os que ficaram sem evidência e o link para cada evidência; ao publicar nova versão do ICP, as notas antigas permanecem consultáveis.

## Limites e dependências

- **Inclui:** tabela `score_runs` e componentes, função de pontuação, critério mínimo e impedimentos, explicação legível e histórico por versão de ICP.
- **Fora de escopo:** aprovação de contas e coortes (SPEC-2-003), aprendizado automático de pesos (Fase 5).
- **Entradas:** `icp_versions` com pesos, `evidences` da SPEC-2-001, matriz M6.
- **Saídas:** `score_runs` imutáveis por conta e versão de ICP, explicação por componente.
- **Atores:** liderança define pesos e lê; prospector executa e lê; vendedor e leitor leem (M6).
- **Superfícies:** função server-side `score-accounts`, colunas e painel de explicação no Skip.
- **Risco e plano B:** sinais pouco preenchidos geram notas baixas por falta de dado; componente "sem evidência" fica separado de "zero" e a conta vai para pesquisa necessária.
- **Rollback:** nova execução não apaga execuções anteriores; basta marcar a execução como descartada.

## Dados e integrações

| Origem/destino | Fonte de verdade | Campos/contrato | Autenticação/permissão | Timeout/retry/idempotência | Tratamento de erro |
|---|---|---|---|---|---|
| `icp_versions` + `evidences` → `score_runs` | versão publicada do ICP | conta, versão do ICP, nota, prioridade, componentes (critério, peso, valor, `evidence_ids`, estado `com_evidencia`/`sem_evidencia`/`impedimento`), executado por, data | `prospector` / `lider_comercial` executam (M6) | chave `account_id + icp_version_id + hash(evidence_ids)`; repetir retorna a mesma execução | critério sem tipo ou peso rejeita a execução |
| IA → justificativa textual | `score_runs` | texto citando apenas `evidence_ids` existentes | server-side, secret do modelo | timeout 30 s, 1 retry | sem justificativa, a explicação estruturada continua visível |

| Regra | Condição | Resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-221 | componente sem evidência | estado `sem_evidencia`, contribui 0 e é exibido separado | nenhuma | Escopo 5.3 |
| RN-222 | impedimento do ICP presente com evidência | conta marcada `impedida` independentemente da nota | liderança pode revisar com motivo na SPEC-2-003 | Escopo 7.1 |
| RN-223 | nova versão do ICP publicada | novas execuções usam a nova versão; execuções e coortes antigas inalteradas | nenhuma | Escopo 7.4, 8.15 |
| RN-224 | justificativa da IA cita fato sem `evidence_id` | justificativa descartada | nenhuma | Escopo 7.6, 16 |
| RN-225 | qualquer nota | nunca altera o estado de revisão da conta | nenhuma | Escopo 8.3 |

## Fluxo e regras

1. Liderança publica ICP com pesos, mínimos e impedimentos.
2. Prospector executa a pontuação para o recorte pesquisado.
3. Sistema calcula componentes a partir das evidências e grava `score_run`.
4. IA redige justificativa opcional citando evidências.
5. Lista mostra nota, prioridade e explicação; contas abaixo do mínimo ou impedidas ficam sinalizadas.

| Cenário | Condição | Resultado esperado | Recuperação |
|---|---|---|---|
| Principal | conta com unidades, região e sinal de expansão evidenciados | nota com três componentes e links | não aplicável |
| Limite | conta sem dado de unidades | componente `sem_evidencia`, nota parcial sinalizada | pesquisa necessária |
| Falha | ICP sem peso em um critério | execução rejeitada com erro legível | liderança corrige e publica nova versão |

## Instruções de execução para o Ethos

1. Ler escopo 5.2, 7.1, 7.4, 8 e SPECs 1-002, 2-001 e 2-000.
2. Alterar somente pontuação, explicação e colunas da lista.
3. Não definir pesos nem calibrar por conta própria.
4. Testes → migração → função de pontuação → explicação → telas.
5. Parar se a liderança não tiver publicado pesos.
6. Manter a nota determinística; IA só no texto.

## Checklist de execução

- [ ] `score_runs` imutáveis e vinculadas à versão do ICP.
- [ ] Componentes distinguem com evidência, sem evidência e impedimento.
- [ ] Mesma entrada e versão produzem a mesma nota.
- [ ] Justificativa da IA validada contra `evidence_ids`.
- [ ] Nota não altera estado de revisão.

## Critérios de aceite

- [ ] **CA-2-05:** cada conta pontuada exibe nota, componentes, pesos e as evidências usadas; componentes sem evidência aparecem separados de zero.
- [ ] **CA-2-06:** publicar nova versão do ICP não altera execuções nem coortes anteriores, e ambas as versões ficam consultáveis.
- [ ] **CA-2-07:** nenhuma conta muda de estado de revisão por causa da nota, provado por teste.
- [ ] **CA-2-08:** repetir a pontuação com as mesmas evidências e versão retorna a mesma nota e a mesma execução.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado | Evidência |
|---|---|---|---|---|
| RED | fixture de ICP com pesos e 8 contas com evidências variadas | rodar testes de pontuação | falham sem função | log RED |
| GREEN | mesma fixture + nova versão do ICP | testes da função + `supabase test db` | CA-2-05 a CA-2-08 passam | log e `score_runs` |
| REFACTOR/REGRESSÃO | 15 contas conhecidas pela liderança | comparar ordenação com a percepção da liderança | divergências registradas, sem ajuste silencioso | relatório de calibração |

**Fixtures:** ICP v1 com 4 critérios e 1 impedimento; contas completa, sem unidades, impedida, abaixo do mínimo e empatada.  
**Erros obrigatórios:** critério sem peso, justificativa com fato não evidenciado, `vendedor` tentando executar pontuação.  
**Evidência:** log dos testes e relatório de calibração assinado pela liderança.

## Handoff e operação

- **Como demonstrar:** pontuar o recorte, abrir a explicação de uma conta, publicar ICP v2 e mostrar a nota antiga preservada.
- **Como operar:** prospector executa após cada lote de pesquisa; liderança ajusta pesos via nova versão.
- **Como monitorar:** proporção de componentes sem evidência e distribuição de notas por coorte.
- **Pendência conhecida:** pesos do ICP v1 dependem da liderança.

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F2-T05 | Criar fixtures e testes RED da pontuação | Ethos | SPEC-2-002 | RED falha em componentes, versão e determinismo | RED | log RED e fixture | F2-T03 | ☐ |
| F2-T06 | Implementar pontuação explicável versionada | Ethos | SPEC-2-002 | CA-2-05 a CA-2-08 passam | GREEN | migração, log e capturas | F2-T05 e pesos publicados | ☐ |
| F2-T07 | Calibrar a ordenação com 15 contas conhecidas | Liderança SV | SPEC-2-002 | divergências registradas e aceitas ou nova versão publicada | REGRESSÃO | relatório de calibração | F2-T06 e F2-T04 | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| — | — | — | — |
