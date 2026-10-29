# Changelog

## 2026-10-29

- Fase 2 reorganizada para andar sem paradas por task: os testes RED entraram na mesma task da construção (10 tasks viraram 4: F2-T01 a F2-T04) e a validação com dados reais (20 contas, calibração com 15 contas e primeira coorte) virou o teste do cliente no fim de cada SPEC.
- SPEC-2-000: decididas a tela de importação completa e a exibição dos contatos sensíveis para `admin` no detalhe da conta; a regressão por papel passou a ser automática, sem login do cliente com usuários de teste.
- SPEC-2-001: construção com fonte simulada e fontes públicas autorizadas; a fonte contratada entra quando a SV liberar a credencial.
- SPEC-2-002: construção com os pesos das fixtures; a liderança passa os pesos reais no teste da SPEC.
- AGENTS.md: ritmo de execução e teste por SPEC.

## 2026-10-23

- Fase 1 encerrada com ressalvas e arquivada em `05_entregas/fase-1/` com `phase-closure-manifest.json`.
- Implementação Skip vinculada como submódulo em `05_entregas/sv-digital-app`.
- Fase 2 liberada: SPEC-2-000 (alinhamento de permissões e matriz M6), SPEC-2-001 (pesquisa e proveniência), SPEC-2-002 (pontuação explicável) e SPEC-2-003 (coortes e aprovação), com tasks F2-T01 a F2-T10.
- F2-T01 absorve as divergências de permissão da Fase 1: importação para `lider_comercial`, leitura de contatos sensíveis por `admin` e tela de usuários/memberships.
- Matriz de rastreabilidade atualizada com SPEC-2-000, CA-2-13 a CA-2-15 e renumeração das tasks da Fase 2.

## 2026-09-28

- Emenda às SPECs da Fase 1: criada a matriz de permissões por papel (M1–M5) na SPEC-1-001 como contrato canônico de autorização, com fatias aplicáveis nas SPEC-1-002 (RN-125) e SPEC-1-003 (RN-144).
- Novo CA-1-13: prova negativa por papel (ação proibida negada e auditada) e revogação de membership com efeito imediato.
- CA-1-09 reescrito para exigir conformidade com a matriz M1–M5 e prova server-side (ocultação no frontend não é prova suficiente).
- fase.md atualizado: critérios de F1-T02 e F1-T08 referenciam a matriz e o CA-1-13.

## 2026-09-22

- Criada a pasta do cliente com o escopo definitivo, matriz de rastreabilidade e pacote da Fase 1.
- Incluída a decisão arquitetural de Supabase como backend para suportar o agente de IA no WhatsApp.
- Publicado o repositório de entrega: https://github.com/kimberlyPrest/SV-digital---Adapta-Native
