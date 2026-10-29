# AP-2026-10-15-gotrue-seed-tokens — Seed de usuários GoTrue + verificação de hipótese antes de documentar

**Task**: F1-T07/F1-T08 (SPEC-1-003) · **Momento**: análise da F1-T08

## Sinais (2, com evidência)
1. Usuários inseridos direto em auth.users falham no login com 500 "Database error querying schema" se os campos de token não seguirem o formato GoTrue: confirmation_token/recovery_token/email_change*/phone_change_token/reauthentication_token = '' (vazio, NUNCA null) e phone = null (único nullable, por causa de UNIQUE). O seed oficial do juliano (migration da Adapta) tem o formato correto; minhas fixtures não tinham.
2. Hipótese documentada sem prova direta vira evidência errada: documentei "app sem conexão ao Supabase" como causa do R01 sem testar o login com a senha real do seed — o champion tinha razão na 1ª tentativa ("entrei no sistema"). Custo: correção de registro pós-fechamento + confusão no teste humano.

## Regras reutilizáveis
- Criar usuário de auth por SQL: copiar o formato do seed oficial (tokens '', phone null) — ou usar admin API (auth.admin.createUser) quando disponível.
- Antes de atribuir CAUSA a uma falha observada, provar o caminho oposto (login com credencial conhecida-certa) — especialmente quando o diagnóstico depende de senha que não se sabe.
- Roteiro de teste humano NUNCA cita senha que não foi verificada no Auth.

## Aplicado em
Fix das 5 fixtures (update auth.users) + correção do roteiro-red.md e changelog (R01 reatribuído).
