# F1-T09 — Demo formal por papel CONCLUÍDA (CA-1-10)

**Data:** 2026-10-22 · **Executante:** Juliano Dossena (Champion, dono da task)
**Roteiro:** spec-1-003-demo-f1t09.md · **App:** v0.0.3 (ref c69a50e, produção)

## Resultado

- Teste humano confirmado pelo champion: **"demo ok"** (2026-10-22 11:17) — os 5 blocos (A–E) executados conforme esperado, sem divergência registrada.
- CA-1-10 provado: cada um dos 5 papéis (admin, lider_comercial, prospector, vendedor, leitor) viu somente telas/ações autorizadas pela matriz M1–M5, na interface real publicada.
- Prova server-side (CA-1-09) já registrada em spec-1-003-green.md: 10/10 via HTTP com JWT real por papel.

## Limpeza (resíduo 0)

- Conta DEMO "0 DEMO F1-T09 (corrija-me)" removida após a prova.
- Base final: 308 contas, todas importado_nao_reconciliado (estado da F1-T06 preservado).
- Nenhum resíduo de prova (0 DEMO, Prova HTTP): verificado por SQL.

## Fechamento

SPEC-1-003 completa (3/3: F1-T07 RED, F1-T08 GREEN, F1-T09 demo).
**FASE 1 COMPLETA: 9/9.**
