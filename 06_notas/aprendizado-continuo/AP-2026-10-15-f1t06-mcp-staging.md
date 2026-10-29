# AP-2026-10-15-f1t06-mcp-staging — Payloads grandes em execute_sql + provas pgtap + atomicidade MCP

**Task**: F1-T06 (SPEC-1-002) · **Momento**: execução do import real

## Sinais (4, todos com evidência na execução)
1. `execute_sql` do MCP TRUNCA payloads grandes (~22KB de CSV embutido → "unterminated dollar-quoted string") sem avisar.
2. pgtap exige `plan(n)` antes de qualquer asserção — mesmo 1 teste ad-hoc ("You tried to run a test without a plan").
3. Um erro em uma chamada MCP reverte TUDO daquela chamada: `grant` + operação juntos falham juntos (o grant some com o rollback do erro seguinte).
4. Export Kommo traz telefones concatenados (2 números num campo, 21–28 dígitos) e apóstrofos-artefato no início de nomes.

## Regras reutilizáveis
- Dado >4KB: tabela de staging carregada em chunks ≤4KB, verificação de md5 do conteúdo reconstruído ANTES de usar, drop da staging depois.
- Suíte pgtap sempre começa com `select extensions.plan(n);`.
- Grants/DDL em chamada MCP PRÓPRIA e anterior à operação que depende deles.
- Sanitizador de export: telefone válido = 10–15 dígitos (descartar e registrar fora disso); strip de apóstrofo inicial.

## Aplicado em
F1-T06: staging 8 chunks + md5 8061e0b4 verificado, import 308/308, staging derrubada, 3 telefones concatenados descartados com registro.
