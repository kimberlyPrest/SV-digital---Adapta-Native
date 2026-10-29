# Mapeamento de colunas — importação da base comercial (PROVISÓRIO)

**Task:** F1-T04 · **SPEC:** SPEC-1-002 · **Status:** provisório — o mapeamento exato depende do export real de 240 leads do Kommo (validado na F1-T06).

## Fixture → modelo (SPEC-1-002 / escopo seção 9)

| Coluna CSV | Entidade.destino | Observações e regras |
|---|---|---|
| `nome` | `accounts.name` | obrigatório |
| `cnpj` | `accounts.cnpj` | normalização: só dígitos (RN-122). Vazio = permitido (CNPJ é opcional no escopo 7.2); ausência não bloqueia importação |
| `site` | `accounts.site` | — |
| `setor` | `accounts.sector` | — |
| `porte` | `accounts.sector`→campo porte futuro | enum: pequeno/medio/grande |
| `regiao` | `accounts.region` | UF |
| `unidades` | campo unidades (futuro em accounts) | sinal de aderência (escopo 5.2) |
| `estagio_legado` | `accounts.status` via taxonomia | **NÃO é etapa real**: "Encaminhado ao vendedor" ≠ oportunidade qualificada (escopo 2.3); mapear para `importado_nao_reconciliado` até reconciliação (F1-T06) |
| `responsavel` | `accounts.owner_id` | nome→usuário na importação real; vazio = `pesquisa_necessaria` (RN-121) |
| `ultima_acao` | `accounts.next_step_due`/atividade | data ISO |
| `origem` | `accounts.source` | `prospeccao_ativa` / `lista_importada` |
| `contato_*` | `contacts.*` | `contato_telefone`/`contato_email` = PII (PM-02); `contato_fonte` vazio → contato em `pesquisa_necessaria` (RN-123); `contato_data_verificacao` vazio → confiança `baixa` |

## Linhas de prova da fixture (12 contas)

| # | Linha(s) | O que exercita |
|---|---|---|
| 1-2 | Mercado Aurora + Filial Centro | duplicidade por CNPJ normalizado igual (RN-122) — sugerir mesma conta |
| 12 | Mercado Aurora - Matriz | 3ª linha com mesmo CNPJ, cargo diferente — duplicidade com contato distinto |
| 3 | Supermercado Integracao | CNPJ ausente + contato sem fonte/data (RN-123) |
| 5 | Mercado Vale Verde | contato sem telefone (canal parcial) |
| 7 | Mercado Bom Preco | origem `lista_importada`, responsável vazio (RN-121) |
| 11 | Mercado Portal | etapa legada "Desqualificado" — não reativa (escopo 1) |
| 4,6,8,9,10 | — | fluxo normal com formatos de telefone variados (RN-122 normalização) |

**Total:** 12 contas · 2 grupos de duplicidade (CNPJ `12345678000195`×3) · 1 sem CNPJ · 2 contatos sem fonte · 5 formatos de telefone distintos · etapas legadas do Kommo.
