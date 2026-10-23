# Fase 2 — Inteligência de contas e construção de listas

## Tasks

| ID | Task | Dono | SPEC | Subseção | Critério binário | Recorte da prova | Evidência esperada | Pré-condições | Ponto de parada | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| F2-T01 | Alinhar permissões do Skip à matriz e criar tela de usuários | Ethos | SPEC-2-000 | Matriz M6 e TDD da SPEC | CA-2-13 a CA-2-15 passam | RED → GREEN | log do teste de tabela e capturas por papel | implementação `f989db7` | `PODE` idêntico a M1–M6 e revogação efetiva | ☐ |
| F2-T02 | Criar fixtures e testes RED de pesquisa e proveniência | Ethos | SPEC-2-001 | TDD da SPEC | RED falha em evidência, conflito e idempotência | RED | log RED e fixture | F2-T01 | testes descrevem regras sem implementá-las | ☐ |
| F2-T03 | Implementar jobs evidências fila de pesquisa e telas | Ethos | SPEC-2-001 | Dados e integrações | CA-2-01 a CA-2-04 passam | GREEN | migrações, log e capturas | F2-T02 | pesquisa funcional em homologação com fonte simulada | ☐ |
| F2-T04 | Pesquisar 20 contas reais do ICP em homologação | Prospector SV | SPEC-2-001 | Handoff e operação | 20 contas com evidências ou em pesquisa necessária | REGRESSÃO | relatório de pesquisa | F2-T03 e fonte autorizada | nenhum dado sem fonte exibido como verificado | ☐ |
| F2-T05 | Criar fixtures e testes RED da pontuação | Ethos | SPEC-2-002 | TDD da SPEC | RED falha em componentes, versão e determinismo | RED | log RED e fixture | F2-T03 | testes descrevem a nota sem implementá-la | ☐ |
| F2-T06 | Implementar pontuação explicável versionada | Ethos | SPEC-2-002 | Fluxo e regras | CA-2-05 a CA-2-08 passam | GREEN | migração, log e capturas | F2-T05 e pesos publicados | notas reproduzíveis e explicadas | ☐ |
| F2-T07 | Calibrar a ordenação com 15 contas conhecidas | Liderança SV | SPEC-2-002 | Handoff e operação | divergências registradas e aceitas ou nova versão publicada | REGRESSÃO | relatório de calibração | F2-T06 e F2-T04 | calibração assinada sem ajuste silencioso | ☐ |
| F2-T08 | Criar fixtures e testes RED de revisão e coortes | Ethos | SPEC-2-003 | TDD da SPEC | RED falha em duplicidade, motivo e coorte concorrente | RED | log RED e fixture | F2-T06 | testes descrevem regras sem implementá-las | ☐ |
| F2-T09 | Implementar lista revisão coortes e exportação | Ethos | SPEC-2-003 | Fluxo e regras | CA-2-09 a CA-2-11 passam | GREEN | migrações, log, capturas e CSV | F2-T08 | revisão e coorte funcionais em homologação | ☐ |
| F2-T10 | Aprovar a primeira coorte real com a liderança | Champion SV | SPEC-2-003 | Handoff e operação | CA-2-12 aprovado sem bypass | REGRESSÃO | aceite e CSV da coorte | F2-T09 e F2-T07 | resultado registrado sem corrigir durante a prova | ☐ |
