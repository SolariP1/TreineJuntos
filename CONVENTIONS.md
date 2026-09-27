# Convenções do projeto — TreinaJunto

> **Leia este arquivo antes de qualquer operação de git** (commit, tag, branch,
> push, PR). Ele é a fonte da verdade sobre o padrão do projeto.

---

## 1. Commits

### 1.1 Autoria

- **Nunca** adicionar `Co-Authored-By: Claude` (ou qualquer co-autor de ferramenta
  de IA) nas mensagens de commit.
- **Nunca** adicionar rodapés do tipo "🤖 Generated with ...".
- O autor do commit é sempre o Lucas. O histórico do projeto é dele.

### 1.2 Formato da mensagem

Conventional Commits, assunto em **português**, no imperativo, minúsculo, sem
ponto final, até 72 caracteres:

```
<tipo>(<escopo>): <assunto>

<corpo opcional — o porquê, não o quê>
```

**Tipos permitidos:**

| Tipo       | Quando usar                                              |
|------------|----------------------------------------------------------|
| `feat`     | nova funcionalidade visível ao usuário                    |
| `fix`      | correção de bug                                           |
| `refactor` | muda estrutura sem mudar comportamento                    |
| `style`    | UI, tema, espaçamento, tipografia — sem lógica            |
| `perf`     | melhoria de performance                                   |
| `test`     | adiciona ou ajusta testes                                 |
| `docs`     | documentação, README, este arquivo                        |
| `build`    | `project.yml`, XcodeGen, dependências, assets, fontes     |
| `chore`    | manutenção que não entra em nenhuma das anteriores        |

**Escopos** (baseados nas features do app): `feed`, `perfil`, `onboarding`,
`portfolio`, `convites`, `disponibilidade`, `chat`, `busca`, `tema`, `core`, `ci`, `deps`.

Exemplos:

```
feat(convites): descontar convite ao iniciar treino
fix(feed): corrigir distância exibida como texto fixo
refactor(core): extrair repositório de parceiros do FeedView
```

### 1.3 Tamanho

Um commit = uma mudança coerente. Se a mensagem precisa de "e" no assunto,
provavelmente são dois commits.

---

## 2. Tags de versão

Toda atualização entregue recebe uma tag **anotada** seguindo SemVer: `vMAJOR.MINOR.PATCH`.

- **MAJOR** — mudança que quebra fluxo ou dados existentes do usuário
- **MINOR** — nova funcionalidade, retrocompatível
- **PATCH** — correção de bug ou ajuste sem nova funcionalidade

### 2.1 Texto padronizado da tag

```
vX.Y.Z — <Título da atualização>

Novidades
- <item>

Correções
- <item>

Interno
- <item>
```

Seções sem conteúdo são omitidas. Comando:

```
git tag -a vX.Y.Z -F docs/releases/vX.Y.Z.md
```

O mesmo texto fica versionado em `docs/releases/vX.Y.Z.md`, para virar changelog
e nota de release depois.

### 2.2 Regras

- Tags sempre anotadas (`-a`), nunca leves.
- A tag aponta para um commit já na `main`.
- Nunca reescrever ou mover uma tag já publicada — corrigiu? nova PATCH.
- Versão 0.x.y enquanto o app não estiver publicado na App Store; o primeiro
  release público é a `v1.0.0`.

---

## 3. Branches

- `main` — sempre compilando. É o que vai para a App Store.
- `feat/<escopo>-<descricao-curta>` — ex.: `feat/convites-saldo-mensal`
- `fix/<escopo>-<descricao-curta>`
- `refactor/<escopo>-<descricao-curta>`

Nunca commitar direto na `main` para mudanças não triviais; abrir branch e
integrar por PR (mesmo sendo projeto solo — o PR é o registro da decisão).

---

## 4. Pull Requests

- Título segue o mesmo formato do commit.
- Corpo responde: **o que muda**, **por que**, **como testar**.
- Sem rodapé de ferramenta de IA.
- Merge por **squash**, mantendo a mensagem no formato da seção 1.2.

---

## 5. O que nunca entra no repositório

- `.DS_Store`, `xcuserdata/`, `DerivedData/`
- `TreinaJunto.xcodeproj` é **gerado** pelo XcodeGen a partir de `project.yml` —
  a fonte da verdade é o `project.yml`.
- Chaves, tokens, certificados, `.p8`, `.p12`, perfis de provisionamento.

---

## 6. Código Swift

- Sem código comentado no repositório — o git guarda o histórico.
- Comentários explicam **por quê**, não **o quê**.
- Nomes de tipos e de código em inglês; textos de interface em português.
- Um tipo público por arquivo, com o nome do arquivo igual ao do tipo.
- Nada de `print()` de depuração no que vai para a `main`.
