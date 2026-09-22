# Fase 1 — Fundação segura, modelo comercial e painel inicial

## Tasks

| ID | Task | Dono | SPEC | Subseção | Critério binário | Recorte da prova | Evidência esperada | Pré-condições | Ponto de parada | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| F1-T01 | Criar testes RED de isolamento e papéis | Ethos | SPEC-1-001 | TDD da SPEC | testes falham antes da RLS | RED | log RED | projeto local | testes descrevem acessos sem implementar política | ☐ |
| F1-T02 | Implementar schema base Auth RLS auditoria e filas | Ethos | SPEC-1-001 | Dados e integrações | CA-1-01 a CA-1-04 passam | GREEN | migrações e log | F1-T01 | schema reproduzível e testes verdes | ☐ |
| F1-T03 | Provar revogação secrets e recuperação do schema | Administrador técnico | SPEC-1-001 | Handoff e operação | regressão completa aprovada | REGRESSÃO | relatório e inventário | F1-T02 | nenhuma credencial exposta e rollback demonstrado | ☐ |
| F1-T04 | Definir fixtures e testes RED do modelo comercial | Ethos | SPEC-1-002 | TDD da SPEC | RED reproduz duplicidade e lacunas | RED | log e fixture | SPEC-1-001 | fixture aprovada sem alterar dados reais | ☐ |
| F1-T05 | Implementar ICP funil entidades e importação idempotente | Ethos | SPEC-1-002 | Fluxo e regras | CA-1-05 a CA-1-08 passam | GREEN | migrações e relatório | F1-T04 | importador funcional em homologação | ☐ |
| F1-T06 | Reconciliar a fotografia atual e validar relatório | Champion SV | SPEC-1-002 | Handoff e operação | base classificada sem liberação indevida | REGRESSÃO | relatório assinado | F1-T05 e export real | lote reconciliado ou isolado com lacunas explícitas | ☐ |
| F1-T07 | Criar roteiro RED e estados da interface | Ethos | SPEC-1-003 | TDD da SPEC | cenários de papel e erro especificados | RED | roteiro e capturas | SPEC-1-001 e 002 | roteiro falha pelas telas ausentes | ☐ |
| F1-T08 | Construir telas e painel inicial no Skip | Ethos | SPEC-1-003 | Fluxo e regras | CA-1-09 a CA-1-12 passam | GREEN | URL e testes | F1-T07 | homologação publicável e backend protegido | ☐ |
| F1-T09 | Executar demonstração da Fase 1 por papel | Champion SV | SPEC-1-003 | Handoff e operação | roteiro completo sem bypass | REGRESSÃO | aceite e capturas | F1-T08 | resultado registrado sem corrigir durante a prova | ☐ |
