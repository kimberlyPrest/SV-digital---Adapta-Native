# Orientações do projeto

- Trate `01_projeto/escopo-definitivo.md` como fonte de verdade do produto.
- Execute as tasks uma por vez, em sequência, sem pedir autorização nem teste entre elas, e registre a evidência no próprio artefato da implementação.
- O teste do cliente é um por SPEC, no fim dela, pelo roteiro da seção "Teste do cliente" da SPEC. Fixtures, arquivos de teste, evidências e usuários de teste são do agente: nunca peça ao cliente para abri-los ou entrar com eles.
- Detalhe de tela que a SPEC não define é decisão do agente, pelos padrões do sistema; conte o que escolheu em vez de perguntar.
- Credenciais e chaves ficam somente em secrets do ambiente server-side; nunca no frontend, commits ou mensagens do WhatsApp.
- Toda integração externa deve ter autenticação, timeout, retry controlado, idempotência e log sem dados sensíveis.
- Alterações de schema passam por migração reproduzível e testes de isolamento/RLS.
- O agente do WhatsApp pode qualificar e sugerir ações, mas não deve inventar preço, prazo, estoque ou política comercial.
