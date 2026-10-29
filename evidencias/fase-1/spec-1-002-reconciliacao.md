# RELATÓRIO DE RECONCILIAÇÃO — F1-T06 (SPEC-1-002)

**Data:** 2026-10-13 · **Executado por:** Ethos (autorização do champion Juliano Dossena, 2026-10-13 "Pode implementar")
**Fonte:** export real Kommo `kommo_export_leads_2026-10-09.xlsx` (308 leads × 41 colunas)
**Mapeamento validado pela consultora Kim (2026-10-09):** (1) etapas-pessoa → responsável; (2) base antiga/reativação → fora_de_escopo, nunca em cadência; (3) CNPJ ausente → reconciliar depois, sem enriquecimento prévio.

## Lote importado

| Campo | Valor |
|---|---|
| batch_id | `36c6330a-6c1a-468f-8b27-fdc0d65fd770` |
| Hash do arquivo (md5) | `8061e0b4700347cfae0ae82e26db0cb2` |
| Status | `importado_nao_reconciliado` — NADA liberado para contato |
| Importados | **308** |
| Duplicados / Incompletos / Rejeitados | 0 / 0 / 0 |
| Contatos criados | 244 |
| Eventos de auditoria (RN-103) | 554 |
| Idempotência | reimport do mesmo hash → replay, 308 contas mantidas (provado) |

## Classificação da base (308 leads)

| Categoria | Volume | % | Destino |
|---|---|---|---|
| Prospecção nova (Kommo) | 251 | 81,5% | contas `importado_nao_reconciliado`, origem `kommo` |
| Etapas-pessoa (Carlos 39, Carla 22, Alessandro 11, Fábio 4, DD ganho 19) | 95 | 30,8% | preservadas em `import_batch_rows.legacy_stage` — responsável a definir na reconciliação |
| Fora de escopo (Contatos SV 23, Clientes a encaminhar 13, Retomada 7, Fornecedores 10, concorrentes 3, Avisos 1) | 57 | 18,5% | origem `fora_de_escopo` — NUNCA entram em cadência |

## Lacunas explícitas (para reconciliação posterior)

| Lacuna | Volume | Regra aplicada |
|---|---|---|
| Sem CNPJ | 308/308 (100%) | RN-16: conta não-reconciliada; reconciliar depois (decisão Kim) |
| Contato sem fonte | 244/244 | RN-123: nasce `pesquisa_necessária`, confiança `baixa`, não-verificável |
| Contato sem telefone e sem e-mail | 104/244 (43%) | conta sem canal — pesquisa necessária |
| Telefone inválido descartado (2 números concatenados) | 3 | registrado; telefone vazio na conta |
| E-mail inválido (`assai.com.br/fornecedores`) | 1 | rejeitado pela validação de formato |
| Títulos duplicados sem CNPJ (fg ferramentas gerais, via atacadista) | 2 pares | flag de dedupe por título — NÃO mesclados automaticamente |
| Venda ≠ 0 com "não fechado" | 5 | flag de qualidade de dados no Kommo |

## Provas executadas (todas com evidência nesta data)

1. **Integridade do CSV**: md5 reconstruído no banco = md5 local (`8061e0b4…`), 309 linhas (cabeçalho + 308).
2. **Import real** pelo caminho autorizado (authenticated + JWT do juliano, papel lider_comercial — M4): 308/308.
3. **Idempotência**: reimport do mesmo hash → `idempotent_replay: true`, 308 contas mantidas.
4. **Regressão RLS**: authenticated sem membership não lê o lote (0 linhas) e invalidação por não-membro altera ZERO linhas (status intacto, lido fora da RLS) — 2/2 ok.
5. **Resíduo zero**: tabela de staging derrubada; nenhum dado de teste no banco; xlsx/CSV ficam fora do git (LGPD).

## Assinatura

- [x] Champion (Juliano Dossena): teste humano aprovado — data: 2026-10-15 ("Testei e funcionou")
- [ ] Consultora (Kim): relatório revisado — data: ______
