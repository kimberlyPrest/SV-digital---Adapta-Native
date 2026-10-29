# AP-2026-10-29-testes-sem-bundler — testar lógica pura sem instalar nada, e blindar função com grant

**Task**: F2-T01 (SPEC-2-000) · **Momento**: implementação e verificação

## Sinais (3, com evidência)

1. **Import de componente React quebra teste de lógica.** `node --test` não resolve
   `use-papel.tsx` porque ele importa React e o projeto está sem `node_modules`. Extrair a matriz
   para um `.ts` puro (`matriz-permissoes.ts`) tornou o teste de tabela executável com o runtime
   nativo do Node 26 — **zero dependência nova**. Bônus: separou contrato (dados) de hook (React).
2. **`vite build`/`npm install` não são confiáveis neste ambiente**, mas o **QA do Skip** compila e
   publica normalmente. Build local deu `Bus error (core dumped)` por memória e `node_modules/.bin`
   ficou vazio. Conclusão: usar a plataforma como build oficial; não gastar tempo com build local.
3. **Dar EXECUTE a uma função `security definer` é abrir a porta — só com checagem dentro.**
   `revoke_member` estava sem grant (tela não funcionava) e sem `is_org_admin` no corpo. Se alguém
   "só" adicionasse o grant para destravar a tela, qualquer usuário autenticado revogaria qualquer
   membership. Regra: grant e checagem de autorização entram **no mesmo commit**, nunca separados.

## Regras reutilizáveis

- Lógica pura (matriz, parser, cálculo) mora em módulo `.ts` sem imports de React → testável com
  `node --test` direto, sem bundler, sem instalar nada.
- Antes de liberar EXECUTE de função `security definer`: verificar se o corpo valida o chamador
  (`auth.uid()` + papel na organização). Sem isso, o grant é escalada de privilégio.
- Teste de auditoria deve filtrar por marco temporal: eventos antigos sem `actor` são histórico,
  não regressão. Medir o que é novo.

## Aplicado em
`src/hooks/matriz-permissoes.ts`, `src/hooks/__tests__/*`, migração `f2t01_permissoes_e_memberships`.
