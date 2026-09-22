# Orientações do projeto

- Trate `01_projeto/escopo-definitivo.md` como fonte de verdade do produto.
- Execute uma task por vez e registre a evidência no próprio artefato da implementação.
- Credenciais e chaves ficam somente em secrets do ambiente server-side; nunca no frontend, commits ou mensagens do WhatsApp.
- Toda integração externa deve ter autenticação, timeout, retry controlado, idempotência e log sem dados sensíveis.
- Alterações de schema passam por migração reproduzível e testes de isolamento/RLS.
- O agente do WhatsApp pode qualificar e sugerir ações, mas não deve inventar preço, prazo, estoque ou política comercial.
