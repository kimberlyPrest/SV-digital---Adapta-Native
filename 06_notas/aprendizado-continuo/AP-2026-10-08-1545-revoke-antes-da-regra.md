# AP-2026-10-08-1545 — Provas RED de regra inexistente caem no revoke antes da regra

- Status: candidato
- Escopo: projeto do cliente (SV Digital — Adapta Native)
- Task/SPEC: F1-T04 / SPEC-1-002
- Sinal: com o endurecimento da F1-T02 (DML revogado a authenticated), uma prova RED de REGRA DE NEGÓCIO inexistente (imutabilidade de ICP publicado, RN-121) não chega até a regra: o UPDATE/INSERT falha antes com 42501 "permission denied" (revoke), não com P0001 (regra). O RED continua válido — prova que a regra não existe — PORÉM o GREEN da F1-T05 exige que a REGRA exista (constraint/trigger com P0001 ou exceção própria), e não apenas o revoke, senão o teste continua "verde por motivo errado".
- Evidência: evidencias/fase-1/spec-1-002-red.txt (CA-1-05: caught 42501, wanted P0001; CA-1-07 idem)
- Regra reutilizável: em provas de regra de negócio sobre tabelas com DML revogado, asserir o SQLSTATE DA REGRA (P0001/23514/etc.) no throws_ok — o 42501 do revoke valida superfície, não regra. Fixtures de escrita em teste usam `set local role postgres` (caminho autorizado), já que papéis humanos não têm mais grant de escrita.
- Quando aplicar: qualquer RED/GREEN de regra de negócio neste projeto a partir da F1-T05.
- Quando não aplicar: provas de PERMISSÃO (RN-125), onde o 42501 é exatamente o efeito esperado.
- Confiança: alta — observado em 2 asserções reais nesta task.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.