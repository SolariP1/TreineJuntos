# Backlog — TreinaJunto

Atualizado em 27/09/2026 (v0.1.1).

Como ler: **Fundação** é o que precisa existir para o app ser um produto e não
um protótipo. **Produto** é o que o usuário percebe. **Depois** são apostas que
ainda precisam de decisão.

O refactor de arquitetura que sustenta tudo isso está em
[docs/ARQUITETURA.md](docs/ARQUITETURA.md), com as fases de `v0.2.0` a `v0.8.0`.

---

## Fundação

Sem isso, nenhuma feature de produto se sustenta.

- [ ] **Identidade de usuário.** O onboarding hoje não coleta nada: os três
      botões chamam o mesmo `onContinue()`. Precisa de cadastro, sessão e
      "quem sou eu" acessível de qualquer tela.
- [ ] **Persistir estado.** Hoje fechar o app apaga tudo. Perfil e rascunhos em
      SwiftData; token no Keychain.
- [ ] **Uma fonte de verdade para o perfil.** `FeedView` cumprimenta "Lucas"
      num literal enquanto `ProfileView` tem outra instância de `UserProfile`.
      Editar o perfil precisa mudar as duas.
- [x] ~~Distância como número em vez de texto~~ — feito na v0.4.0
      (`distanceInMeters`), o que destravou ordenar e filtrar por raio.
- [ ] **Localização real.** O número existe, mas é fixo no código. Falta
      CoreLocation e consulta por proximidade de verdade.
- [ ] **Distância no formato brasileiro.** `DistanceFormatter` escreve
      `1.2km` com ponto, porque a fase 3 preservou o visual existente.
      Em pt-BR o certo é `1,2 km` — usar `MeasurementFormatter` com o locale.
- [ ] **Push notification.** Convite para treinar *agora* que chega depois não
      serve para nada. Sem push, o produto não funciona.

## Produto

### Academia e convites (sua ideia de 23/09)

- [ ] Campo `gym` no perfil, ao lado da cidade.
- [ ] Coletar no onboarding e permitir editar no perfil.
- [ ] Mostrar a academia no card do Feed, junto de cidade e distância.
- [ ] Flag `hasInvites` — "seu plano dá convites?".
- [ ] Se sim: quantos o plano dá e quantos ainda restam.
- [ ] Ao iniciar um treino, perguntar "vai usar um convite?" — e descontar 1 se
      a resposta for sim. Quem não tem convite não vê pergunta nenhuma.
- [ ] Exibir no Feed os convites disponíveis e a academia.

> **Decisões em aberto** (levantadas em 23/09, ainda de pé):
> - O saldo zera todo mês junto com o plano, ou é total fixo?
> - "Iniciar um treino" é marcar disponibilidade, ou um momento separado?
> - Os convites no Feed são os **meus** ou os de cada parceiro listado?
>   Esta terceira muda a feature inteira: se for a dos outros, o app ganha
>   uma mecânica nova — *quem pode me levar na academia dele*.

### Defeitos encontrados

- [ ] **O toast nunca aparece.** Ele é desenhado com `padding(.bottom, 12)`,
      mas a tab bar flutuante ocupa ~90pt — então todo aviso de "Convite
      enviado" fica escondido atrás dela. É anterior ao refactor: nenhuma
      confirmação de ação chega ao usuário hoje.

### Fechar o que já está desenhado

- [ ] **Chat.** A aba existe como placeholder. Convite aceito sem lugar para
      combinar horário morre ali.
- [ ] **Busca.** A aba existe como placeholder. Filtro por modalidade, horário
      e distância.
- [ ] **Convidar de verdade.** Hoje `invite()` só mostra um toast e guarda um
      `Set<UUID>` local. Nada sai do aparelho.

### Dar lastro ao que hoje é fachada

O `PartnerPortfolio` já modela **confiabilidade**, **sequência**, **avaliações**
e **medalhas** — mas tudo é gerado por `sample(for:)` a partir do nome da
pessoa. A estrutura de dados mais valiosa do app está pronta e vazia.

- [ ] **Confirmar presença.** Sem isso, confiabilidade é número inventado.
      É a métrica que resolve o maior medo do usuário: marcar e levar bolo.
- [ ] **Avaliar depois do treino.** Só quem treinou junto avalia.
- [ ] **Sequência real**, contada a partir de treinos confirmados.
- [ ] **Medalhas** a partir de fatos, não de `seed % 4`.

## Depois

Apostas — nenhuma deve começar antes da Fundação.

- [ ] **Parceiro fixo.** O interesse "Parceiro fixo" já existe no catálogo, mas
      não faz nada. Treino recorrente com a mesma pessoa é retenção, e é o que
      transforma o app de busca em rotina.
- [ ] **Compatibilidade de verdade.** Hoje é `70 + (seed % 28)`. Cruzar esporte,
      horário, nível e academia é o diferencial defensável do produto.
- [ ] **Grupos.** "Grupo/comunidade" também já está no catálogo sem função.
- [ ] **Segurança.** Treinar com desconhecido é o risco real do app: denúncia,
      bloqueio, primeiro encontro em local público.
- [ ] **Parceria com academias.** A feature de convites já aponta para cá — a
      academia tem interesse em levar visitante.

## Dívida técnica

- [ ] Zerar `.swiftlint-baseline.json`: 9 violações, todas em Views grandes.
      Cada fase do refactor encolhe a lista; quando chegar a zero, o arquivo
      é apagado.
- [ ] Teste para cada ViewModel criado, na pasta da feature em
      `Tests/TreinaJuntoTests/Features/`.
- [ ] Testes de snapshot dos componentes do DesignSystem, depois da fase 2.
