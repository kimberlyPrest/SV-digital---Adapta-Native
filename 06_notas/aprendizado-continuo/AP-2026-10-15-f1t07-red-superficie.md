# AP-2026-10-15-f1t07-red-superficie — RED em superfície real + divergência de teste humano

**Task**: F1-T07 (SPEC-1-003) · **Momento**: execução e teste humano

## Sinais (2, com evidência)
1. App Skip já existia (login com logo SV, criado antes do handoff) — o RED não precisou de app novo: publicar o existente (sem conexão ao Supabase) deu a superfície real para provar R01. Publish é seguro (versão anterior publicável = rollback).
2. Teste humano divergiu na 1ª tentativa ("entrei no sistema" vs. falha esperada). Resolução: reprodução assistida imediata (mesmo app, mesma senha → "Erro de autenticação") + 2º teste do champion confirmou. Causa provável da divergência: confusão entre "página carregou" e "autenticou", ou senha diferente na 1ª tentativa.

## Regras reutilizáveis
- RED de interface: publicar a superfície mínima existente (login sem backend) já prova o primeiro passo do roteiro; os demais falham por construção (rotas ausentes — listar rotas reais do app como evidência).
- Teste humano divergente: não discutir — reproduzir assistido na hora, registrar as duas tentativas no relatório, e pedir novo teste explícito.
- Provas server-side (matriz por papel) independem do frontend: executá-las no banco torna o RED robusto mesmo com UI ambígua.

## Aplicado em
F1-T07: publish do 61901 (ref bdf5f80), R01 com captura, provas 10/10, roteiro com contrato para a F1-T08.
