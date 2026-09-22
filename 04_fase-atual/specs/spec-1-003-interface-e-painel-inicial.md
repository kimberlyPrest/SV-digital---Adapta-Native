# SPEC-1-003 Interface operacional e painel inicial no Skip

**Fase:** 1  
**Status:** planejada  
**Dono:** Champion SV  
**Origem no escopo:** seções 2, 7, 11 e Fase 1  
**Degrau da solução:** recurso nativo da plataforma — construir no Skip as telas sobre o contrato Supabase já definido.

## Contexto e decisões fechadas

- **Estado atual:** informações estão dispersas no Kommo, documentos e imagens de painel.
- **Estado desejado:** o time visualiza e mantém ICP, contas, contatos, coortes, pendências e linha de partida numa interface única.
- **Decisões fechadas:** frontend sem secret privilegiado; indicadores exibem período, origem e cobertura; interface não executa contato nesta fase.
- **Bloqueios:** SPEC-1-001 e SPEC-1-002 em GREEN.

## Resultado observável

O Champion demonstra no Skip o cadastro do ICP, a revisão de uma conta, a correção de uma pendência e o painel inicial com cobertura dos dados.

## Limites e dependências

- **Inclui:** login, navegação, telas de ICP, contas, contatos, importações, fila de correção e dashboard inicial.
- **Fora de escopo:** pesquisa automática, mensagens, WhatsApp, agentes e CRM.
- **Entradas:** APIs e RLS das SPECs anteriores.
- **Saídas:** aplicação publicada em ambiente de homologação e roteiro de demonstração.
- **Permissões:** líder edita ICP; prospector edita registros; vendedor leitura; leitor somente painéis.
- **Superfícies:** projeto Skip e cliente Supabase público.
- **Risco e plano B:** limitação de componente no Skip; usar componente simples preservando contrato e acessibilidade.
- **Rollback:** republicar versão anterior do app; dados permanecem no Supabase.

## Dados e integrações

| Origem/destino | Fonte | Contrato | Permissão | Erro |
|---|---|---|---|---|
| Skip ↔ Supabase | Supabase | tipos gerados do schema | JWT + RLS | mensagem amigável + correlation id |

| Regra | Condição | Resultado | Exceção | Fonte |
|---|---|---|---|---|
| RN-141 | indicador calculado | mostrar valor, janela e cobertura | cobertura ausente impede interpretação como zero | Escopo 2.2 |
| RN-142 | ação sem permissão | ocultar ou desabilitar e manter proteção server-side | nenhuma | Escopo 14.1 |
| RN-143 | registro incompleto | aparecer na fila de correção | importado não reconciliado fica separado | Escopo Fase 1 |

## Fluxo e regras

1. Usuário entra e vê a visão adequada ao papel.
2. Navega para contas e revisa dados e origem.
3. Corrige uma pendência permitida.
4. Abre o painel e filtra período, origem, coorte e responsável.
5. Sai e a sessão é invalidada conforme configuração.

| Cenário | Condição | Resultado | Recuperação |
|---|---|---|---|
| Principal | líder autenticado | telas e ações administrativas disponíveis | não aplicável |
| Limite | base sem dados | estados vazios explicam a próxima ação | importar ou criar registro |
| Falha | sessão expirada | nenhuma mutação ocorre; usuário volta ao login | autenticar novamente |

## Instruções de execução para o Ethos

1. Ler SPEC-1-001 e SPEC-1-002.
2. Alterar somente o projeto Skip e configuração pública do cliente Supabase.
3. Não colocar secrets, regras apenas client-side ou dados fictícios em produção.
4. Criar testes de fluxo → telas → estados de erro → publicar homologação.
5. Parar se uma ação exigir burlar RLS ou usar service role.
6. Manter versão anterior publicável.

## Checklist de execução

- [ ] Login e logout funcionam.
- [ ] Navegação corresponde aos papéis.
- [ ] Telas possuem loading, vazio, erro e sucesso.
- [ ] Filtros do painel informam período e cobertura.
- [ ] Nenhum secret aparece no frontend.
- [ ] Roteiro do Champion foi executado.

## Critérios de aceite

- [ ] **CA-1-09:** cada papel vê somente telas e ações autorizadas.
- [ ] **CA-1-10:** o Champion completa o roteiro sem editar diretamente o banco.
- [ ] **CA-1-11:** painel diferencia zero, dado ausente e dado incompleto.
- [ ] **CA-1-12:** erro de rede ou sessão não produz mutação parcial.

## TDD da SPEC

| Etapa | Prova | Ação | Resultado | Evidência |
|---|---|---|---|---|
| RED | roteiro falha sem telas e estados | teste de navegação em homologação | passos incompletos | captura RED |
| GREEN | executar roteiro por papel | testes do projeto + demonstração | CA-1-09 a CA-1-12 passam | vídeo curto/capturas |
| REFACTOR/REGRESSÃO | rede offline, sessão expirada e base vazia | simular estados | interface recupera sem corrupção | checklist de regressão |

**Fixtures:** usuários por papel e base importada da SPEC-1-002.  
**Erros obrigatórios:** 401, 403, timeout, lista vazia e validação de formulário.  
**Evidência:** URL de homologação, capturas e checklist assinado.

## Handoff e operação

- **Como demonstrar:** roteiro login → ICP → conta → correção → painel.
- **Como operar:** Champion administra; prospector usa fila diária.
- **Como monitorar:** erros de frontend e falhas das APIs.
- **Pendência conhecida:** nenhuma.

## Tasks vinculadas

| ID | Task | Dono | SPEC | Critério | Recorte da prova | Evidência esperada | Pré-condições | Status |
|---|---|---|---|---|---|---|---|---|
| F1-T07 | Criar roteiro RED e estados da interface | Ethos | SPEC-1-003 | cenários de papel e erro especificados | RED | roteiro e capturas | SPEC-1-001 e 002 | ☐ |
| F1-T08 | Construir telas e painel inicial no Skip | Ethos | SPEC-1-003 | CA-1-09 a CA-1-12 | GREEN | URL e testes | F1-T07 | ☐ |
| F1-T09 | Executar demonstração da Fase 1 por papel | Champion SV | SPEC-1-003 | roteiro completo sem bypass | REGRESSÃO | aceite e capturas | F1-T08 | ☐ |

## Emendas

| Data | Origem do sinal | Micro-spec/task | Motivo |
|---|---|---|---|
| | | | |
