# TODO — TreinaJunto

## Perfil: academia e convites

Ideia anotada em 23/09/2026. Nada disso está implementado ainda — hoje o
`UserProfile` em `TreinaJunto/Models.swift` só tem `city`.

### 1. Academia que frequenta

- [ ] Adicionar campo `gym` (academia que frequenta) ao `UserProfile`, além da cidade que já existe.
- [ ] Incluir o campo na criação de perfil (`OnboardingView`) e na edição (`EditProfileView`).
- [ ] Mostrar a academia no card do Feed, junto com a cidade/distância.

### 2. Flag de convites

- [ ] Adicionar ao perfil uma flag `hasInvites` — "possui convites no plano?".
- [ ] Se sim, guardar **quantos convites** o plano da pessoa dá (`inviteCount`) e quantos
      ainda restam disponíveis (`invitesAvailable`).
- [ ] Pedir essas informações na criação do perfil, logo depois da academia
      (o campo de quantidade só aparece se a flag estiver ligada).

### 3. Perguntar ao iniciar um treino

- [ ] Quando a pessoa **tem convites**, todo início de treino abre uma pergunta:
      "vai usar um convite neste treino?".
- [ ] Se ela responder que sim, descontar 1 do saldo disponível.
- [ ] Se não tem convites, não perguntar nada — o fluxo segue direto.

### 4. Mostrar no Feed

- [ ] Exibir no Feed quantos convites a pessoa ainda tem disponíveis.
- [ ] Exibir também a academia que ela frequenta.

### Pontos a decidir depois

- O saldo de convites zera todo mês (junto com o plano) ou é um total fixo?
- "Iniciar um treino" é marcar disponibilidade (`MarkAvailabilitySheet`) ou um
  momento separado, quando o treino realmente começa?
- Os convites do Feed são os **meus** (saldo próprio, sempre visível) ou os de
  cada parceiro listado (para eu saber quem pode me levar na academia dele)?
