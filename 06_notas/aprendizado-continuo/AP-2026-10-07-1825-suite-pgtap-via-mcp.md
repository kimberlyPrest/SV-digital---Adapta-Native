# AP-2026-10-07-1825 — Execução de suíte pgtap via MCP em projeto Supabase remoto

- Status: candidato
- Escopo: projeto do cliente (SV Digital — Adapta Native)
- Task/SPEC: F1-T01 / SPEC-1-001
- Sinal: o sandbox bloqueia portas Postgres (5432/6543) — só HTTPS sai; psql e psycopg2 não alcançam o host. A suíte pgtap foi executada bloco a bloco via MCP execute_sql, cada bloco em transação própria com BEGIN/ROLLBACK, provando RED sem persistir nada.
- Evidência: evidencias/fase-1/spec-1-001-red.txt (12 not ok + 1 ok; seção RESÍDUO VERIFICADO: 0 tabelas/0 usuários pós-execução, reconfirmado no fechamento)
- Regra reutilizável: quando o executor não tem acesso ao protocolo Postgres, executar testes pgtap como blocos BEGIN...ROLLBACK via MCP execute_sql — o rollback é a garantia de reversibilidade; nunca migrar schema de produto para "facilitar" o teste.
- Quando aplicar: suítes pgtap em projetos Supabase remotos acessados só por MCP; provas RED que exigem banco real.
- Quando não aplicar: ambiente local com psql/CLI disponível (usar supabase test db); testes que exigem isolamento entre conexões.
- Confiança: alta — método exercitado ponta a ponta nesta task, com verificação de resíduo antes e depois.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.

# AP-2026-10-07-1825b — Lições de execução pgtap no Supabase gerenciado

- Status: candidato
- Escopo: projeto do cliente (SV Digital — Adapta Native)
- Task/SPEC: F1-T01 / SPEC-1-001
- Sinal: quatro restrições da plataforma confirmadas por erro real durante a execução: (1) auth.users exige id explícito (não há default); (2) SET LOCAL não aceita subconsulta nem valor dinâmico de DO block via executor remoto — usar UUIDs fixos determinísticos; (3) provas negativas exigem DADO existente — sem RLS o usuário VÊ o dado proibido e a asserção falha (é isso que caracteriza o RED); (4) pgtap neste projeto vive no schema extensions, sem eq() — usar is(); plan() é obrigatório antes de qualquer asserção.
- Evidência: erros 42601/42883/P0001 observados e corrigidos durante a execução; log em evidencias/fase-1/spec-1-001-red.txt (seção CORREÇÕES APLICADAS)
- Regra reutilizável: em fixtures pgtap para Supabase gerenciado: IDs fixos no setup, plan() antes das asserções, funções pgtap sempre com prefixo extensions., e provas negativas construídas sobre dados que já existem.
- Quando aplicar: qualquer suíte pgtap nova neste projeto (F1-T02 em diante).
- Quando não aplicar: versões futuras de pgtap que exponham eq() no schema público.
- Confiança: alta — cada lição nasceu de erro observado, não de inferência.
- Privacidade: sem segredo, dado pessoal ou conteúdo bruto.