# Backlog — TreinaJunto

Atualizado em 28/09/2026, sobre a v0.10.0 mais o PR #13.

**Como ler.** O que está em *Agora* é o caminho crítico: cada item destrava o
seguinte. *Depende de você* são coisas que eu não consigo fazer sozinho.
*Depois* são apostas que não devem começar antes da fundação.

Decisões de produto: [docs/PRODUTO.md](docs/PRODUTO.md).
Arquitetura e plano de migração: [docs/ARQUITETURA.md](docs/ARQUITETURA.md).

---

## Já está pronto

Para não perder de vista o que existe.

- [x] Arquitetura em camadas, 7 fases, `v0.2.0` a `v0.8.0`
- [x] 97 testes, CI com 3 checks, dívida de lint zerada
- [x] Sessão que sobrevive a fechar o app (`AppSession`)
- [x] Perfil gravado em disco (SwiftData)
- [x] Treino modelado: três estados, party de 2 a 6, presença
- [x] Saldo de convites que zera sozinho na virada do mês
- [x] Abrir, iniciar e encerrar treino pela interface
- [x] Aviso de quantos convites a party vai gastar, na hora de abrir

---

## Agora — o caminho crítico

Em ordem. Cada um destrava o próximo.

### 1. Ligar convite a treino

Hoje o 👋 no card manda um convite que não leva a lugar nenhum: ele guarda um
`Set<UUID>` e mostra um toast. **Nada conecta duas pessoas.**

- [ ] O 👋 passa a convidar a pessoa para o **meu treino aberto**
- [ ] Aceitar um convite **põe a pessoa dentro do treino**
- [ ] O Feed mostra treinos abertos de quem está perto, não só pessoas
- [ ] Sair de um treino antes de começar

**Por que primeiro:** sem isso, party, presença, avaliação e confiabilidade
não têm como existir. É a peça que falta para o app fazer o que promete.

### 2. O aceite e o chat

- [ ] **Card de quem aceitou** ao abrir o app, com "Conversar" e "Depois",
      passando pra frente quando houver mais de um
- [ ] Marcar cada aceite como visto — ninguém vê a mesma novidade duas vezes
- [ ] Faixa discreta, e não modal, quando o aceite chega com o app aberto
- [ ] **Chat**: a aba deixa de ser placeholder e lista as conversas
- [ ] "Conversar" leva direto à conversa certa

> **Decisão pendente:** conversa por pessoa ou por treino?
> Ver [PRODUTO.md §8.3](docs/PRODUTO.md) — recomendo **por treino**, porque
> party sem conversa em grupo não funciona.

### 3. Confirmar presença

- [ ] Tela ao encerrar: quem apareceu de fato
- [ ] Hoje o encerrar marca só o anfitrião, porque ninguém consegue entrar

**Por que:** é o que resolve o maior medo do usuário — marcar e levar bolo.
E é de onde a confiabilidade sai.

### 4. Dar lastro ao que hoje é fachada

O `PartnerPortfolio` modela confiabilidade, sequência, avaliações e medalhas,
mas tudo vem de `seed % 4`. A estrutura mais valiosa do app está pronta e
vazia.

- [ ] Confiabilidade calculada de presenças confirmadas
- [ ] Avaliar depois do treino — só quem treinou junto avalia
- [ ] Sequência contada de treinos reais
- [ ] Medalhas a partir de fatos

### 5. Live Activity

- [ ] Target de **Widget Extension** (não roda no target principal)
- [ ] Treino iniciado aparece no topo da tela e na Dynamic Island
- [ ] Atualização por **APNs** quando o app está fechado

### 6. Fotos e comentários no treino

- [ ] Mural dentro do treino iniciado, entre participantes
- [ ] **Comprimir a foto no aparelho** antes de subir
- [ ] **Limitar fotos por treino**

> As duas últimas não são detalhe: Storage é o primeiro limite do plano
> gratuito do Supabase que você vai bater. Sem elas, semanas.

---

## Depende de você

Coisas que eu não consigo fazer sozinho.

### Supabase

- [ ] **Criar o projeto** em supabase.com, região **São Paulo (sa-east-1)**
- [ ] Rodar o schema de [PRODUTO.md §5](docs/PRODUTO.md) no SQL Editor
- [ ] Me passar a **URL** e a **chave anon** (a anon é pública por design)
- [ ] **Nunca** me passar a `service_role` nem pô-la no app — ela ignora
      todas as políticas de segurança

Depois disso eu faço:

- [ ] Políticas de RLS (só quem treinou junto avalia, etc.)
- [ ] Função `invites_left` no banco
- [ ] `RemoteWorkoutRepository`, `RemotePartnerRepository`, etc.
- [ ] Edge Function para o **hash do CPF** — o pepper não pode ir no binário

### Conta de desenvolvedor Apple

- [ ] Necessária para Sign in with Apple, APNs e publicar
- [ ] Chave do APNs (`.p8`) — vai para o servidor, **nunca** para o repo

### Decisões que ainda não precisam ser tomadas, mas vão precisar

- [ ] Limite de fotos por treino
- [ ] O que acontece com um treino aberto que ninguém entrou — expira quando?
- [ ] Party pode ser aberta a quem não foi convidado, ou é só por convite?

---

## Cadastro e identidade

- [ ] **Sign in with Apple** de verdade (decidido em 27/09)
- [ ] **CPF como hash**, calculado no servidor com pepper
- [ ] **Verificação de telefone por SMS**
- [ ] **Onboarding que coleta**: nome, cidade, academia, esportes
- [ ] **Keychain** para o token — `UserDefaults` guarda só o marcador de
      sessão, nunca credencial
- [ ] Google e e-mail ficam desabilitados até haver servidor

---

## Academia e convites

- [ ] Campo `gym` no perfil, ao lado da cidade
- [ ] Coletar no onboarding e permitir editar no perfil
- [ ] Cadastro do plano: tem convites? quantos por mês?
- [ ] Mostrar a academia e **os convites da outra pessoa** no card do Feed —
      *quem pode me levar na academia dele*
- [ ] Meu saldo no meu perfil, junto do cadastro do plano

---

## Defeitos conhecidos

- [ ] **O toast nunca aparece.** `padding(.bottom, 12)` contra uma tab bar
      flutuante de ~90pt. Nenhuma confirmação de ação chega ao usuário hoje.
- [ ] **Duas fontes de verdade para o perfil.** `FeedGreeting` cumprimenta
      "Lucas" e mostra "L" em literais, enquanto o Perfil lê do repositório.
      Editar o nome não muda a saudação.
- [ ] **Distância no formato errado.** `DistanceFormatter` escreve `1.2km`
      com ponto; em pt-BR é `1,2 km`. Usar `MeasurementFormatter` com locale.
- [ ] **Localização é fixa no código.** `distanceInMeters` existe, mas os
      valores são constantes. Falta CoreLocation de verdade.

---

## Fundação que ainda falta

- [ ] **Push notification.** Convite para treinar *agora* que chega depois
      não serve. Sem push, o produto não funciona.
- [ ] **Busca.** A aba é placeholder. Filtro por modalidade, horário e
      distância.

---

## Antes de publicar

- [ ] **Política de privacidade** — obrigatória, e mais ainda com CPF e
      localização
- [ ] **Apagar conta e dados** dentro do app — exigência da Apple e da LGPD
- [ ] **Sign in with Apple** presente, já que há login do Google na tela
      (diretriz 4.8)
- [ ] Ícone, capturas de tela, texto da App Store
- [ ] Revisar o que o app pede de permissão e por quê

---

## Depois

Apostas. Nenhuma deve começar antes do caminho crítico.

- [ ] **Parceiro fixo.** O interesse já existe no catálogo sem função. Treino
      recorrente é o que transforma busca em rotina.
- [ ] **Compatibilidade de verdade.** Hoje é `70 + (seed % 28)`. Cruzar
      esporte, horário, nível e academia é o diferencial defensável.
- [ ] **Grupos.** "Grupo/comunidade" também está no catálogo sem função.
- [ ] **Segurança.** Denúncia, bloqueio, primeiro encontro em local público.
      É o risco real de um app onde desconhecidos se encontram.
- [ ] **Parceria com academias.** A feature de convites já aponta para cá.

---

## Dívida técnica

- [ ] Testes de snapshot dos componentes do DesignSystem
- [ ] Testes de interface do fluxo principal (abrir → começar → encerrar)
- [ ] `SampleData` vai ter que sair quando a API chegar — hoje ele é o
      dublê e a semente do primeiro perfil ao mesmo tempo
