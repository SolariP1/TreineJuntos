# Arquitetura — TreinaJunto

Escrito em 27/09/2026, sobre a v0.1.1.

Este documento tem duas partes: **o que está errado hoje** e **para onde vamos**.
A segunda só faz sentido depois da primeira.

---

## Parte 1 — Diagnóstico

O app funciona e é bonito. O problema não é qualidade de código: é que **não
existe lugar para um backend entrar**. Sete pontos, do mais grave ao menos.

### 1.1 Cada tela inventa os próprios dados

```swift
// FeedView.swift
@State private var people = WorkoutPartner.sample
Text("Olá, Lucas 👋")          // literal, cravado na View

// ProfileView.swift
@State private var profile = UserProfile()   // outra instância, sem relação
```

`FeedView` e `ProfileView` têm **fontes de verdade diferentes para a mesma
pessoa**. Editar o nome no perfil não muda a saudação do Feed. Não é um bug a
corrigir com um `@Binding` — é o sintoma de não existir uma camada de dados.

### 1.2 Nada sobrevive a fechar o app

Todo o estado mora em `@State` dentro de Views. Convites respondidos, fotos
escolhidas, perfil editado: tudo volta ao padrão no próximo lançamento. Hoje
isso parece um detalhe de protótipo. No dia em que alguém usar o app de
verdade, é o primeiro motivo de desinstalação.

### 1.3 Não existe usuário

```swift
// RootView.swift
@State private var isLoggedIn = false

// OnboardingView.swift — os três botões fazem a mesma coisa
Button(action: onContinue) { ... }
```

O onboarding **não coleta nada**. Não há cadastro, identidade, nem sessão.
Um app cujo produto é conectar duas pessoas precisa saber quem é cada uma —
essa é a fundação que falta, não uma feature futura.

### 1.4 O modelo de domínio depende de SwiftUI

```swift
// Models.swift
import SwiftUI

struct WorkoutPartner: Identifiable, Hashable {
    var gradient: LinearGradient { Theme.avatarGradients[...] }
}
```

`WorkoutPartner` é um conceito de negócio — uma pessoa que treina. Ele não
deveria saber o que é um gradiente. Enquanto souber, não dá para compartilhar
esse modelo com um servidor, um widget ou um app de watch, e todo teste de
regra carrega a camada de UI junto.

### 1.5 O gerador de dados falsos mora dentro do modelo

`PartnerPortfolio.sample(for:)` tem 70 linhas de dados sintéticos **dentro do
tipo de domínio**. Quando a API chegar, o modelo e o dublê estão no mesmo
arquivo, e a tentação vai ser manter os dois.

### 1.6 Esporte é `String` — e a paleta está disfarçada de esporte

Este é o achado menos óbvio e o mais incômodo. `Playful.style(for:)` aparece
**26 vezes** no código, e na maioria delas não tem nada a ver com esporte:

```swift
// FeedView.swift — o badge de notificação não é sobre corrida
.background(Playful.style(for: "Corrida").base, in: Circle())

// MainTabView.swift — a cor da tab bar também não
.tint(Playful.style(for: "Corrida").base)

// ProfileView.swift — nem a medalha de sequência
("flame.fill", "7 dias seguidos", Playful.style(for: "Corrida"))
```

"Corrida" virou sinônimo de *laranja*. Trocar a cor do esporte Corrida hoje
muda a tab bar, o badge de notificação e as medalhas. São duas coisas
diferentes — **paleta** e **identidade do esporte** — compartilhando a mesma
tabela. Além disso, esporte como `String` significa que um typo compila e
falha silencioso em tempo de execução.

### 1.7 Views de 500 linhas com regra de negócio dentro

`ProfileView` (491), `PartnerPortfolioView` (517), `EditProfileView` (295 no
corpo do struct). Dentro delas, regras reais:

```swift
// FeedView.swift
private func invite(_ person: WorkoutPartner) {
    guard !invited.contains(person.id) else { return }   // regra de negócio
    invited.insert(person.id)
    toast("Convite enviado para \(person.name)!")
}
```

"Não pode convidar duas vezes" é uma regra do produto. Ela está enterrada numa
View, onde nenhum teste alcança. São as 9 violações registradas na baseline do
SwiftLint — a dívida já está medida.

---

## Parte 2 — Para onde vamos

### 2.1 Princípio

Uma regra só, da qual tudo o resto decorre:

> **A View não sabe de onde vem o dado.**

Se essa regra valer, trocar dados falsos por uma API é mudar uma linha de
composição, não reescrever telas.

### 2.2 Camadas

```
TreinaJunto/
├── App/               entrada, composição das dependências, rota raiz
├── DesignSystem/      paleta, tipografia, componentes, mascote
├── Domain/            modelos e regras puras — SEM import SwiftUI
├── Data/              repositórios: protocolo + implementações
└── Features/
    ├── Feed/          FeedView + FeedViewModel
    ├── Profile/
    ├── Onboarding/
    ├── PartnerPortfolio/
    └── Availability/
```

A dependência aponta **sempre para dentro**: `Features` → `Domain`.
`Domain` não conhece ninguém. `Data` implementa o que `Domain` declara.

### 2.3 As cinco mudanças estruturais

**a) `Domain` sem SwiftUI**

`WorkoutPartner` vira dado puro. O gradiente passa a ser uma extensão que mora
no `DesignSystem`:

```swift
// Domain/WorkoutPartner.swift — sem import SwiftUI
struct WorkoutPartner: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let age: Int
    let sport: Sport
    let distanceInMeters: Int      // número, não "450m"
}

// DesignSystem/WorkoutPartner+Style.swift
extension WorkoutPartner {
    var gradient: LinearGradient { ... }
}
```

Repare no `distanceInMeters`. Hoje distância é a `String` `"450m"` — não dá
para ordenar por proximidade nem filtrar por raio, que são exatamente as duas
coisas que o app precisa fazer. Formatar é trabalho da View.

**b) `Sport` vira enum**

```swift
enum Sport: String, CaseIterable, Codable, Sendable {
    case corrida, musculacao, funcional, ciclismo, yoga, natacao
}
```

O compilador passa a pegar o typo, o `switch` passa a ser exaustivo e
adicionar um esporte vira uma mudança que o Xcode aponta onde tratar.

**c) Separar paleta de esporte**

```swift
// DesignSystem/Palette.swift — cores do app, sem relação com esporte
enum Palette {
    static let accent = Color(...)      // era style(for: "Corrida").base
    static let violet = Color(...)
    static let mint   = Color(...)
}

// DesignSystem/Sport+Style.swift — identidade visual de cada esporte
extension Sport { var style: SportStyle { ... } }
```

As 26 chamadas se dividem: as que falam de esporte continuam; as que só
queriam uma cor passam a usar `Palette`. Depois disso, mudar a cor da Corrida
não mexe na tab bar.

**d) Repositórios com protocolo**

O coração da coisa:

```swift
// Domain/PartnerRepository.swift
protocol PartnerRepository: Sendable {
    func nearbyPartners() async throws -> [WorkoutPartner]
    func portfolio(for id: UUID) async throws -> PartnerPortfolio
    func invite(_ id: UUID) async throws
}
```

Hoje existe `InMemoryPartnerRepository` (os `sample` de agora, tirados do
modelo). Amanhã existe `RemotePartnerRepository`. **As Views não mudam.**

Os métodos já nascem `async throws` mesmo com dados locais — assim a UI já
lida com carregando e erro desde o primeiro dia, em vez de ganhar esses
estados num refactor de emergência.

**e) ViewModel por feature, com `@Observable`**

O deployment target já é iOS 17, então `@Observable` está disponível:

```swift
@Observable @MainActor
final class FeedViewModel {
    private(set) var state: LoadState<[WorkoutPartner]> = .loading
    private(set) var invited: Set<UUID> = []

    private let partners: PartnerRepository

    init(partners: PartnerRepository) { self.partners = partners }

    func invite(_ partner: WorkoutPartner) async { ... }   // testável
}
```

A regra "não pode convidar duas vezes" sai da View e vira teste em
`Tests/TreinaJuntoTests/Features/Feed/`.

### 2.4 Sessão e persistência

- `AppSession` (`@Observable`) substitui o `@State isLoggedIn` do `RootView`
  e passa a ser a única resposta para "quem está usando o app".
- **SwiftData** para o perfil e o rascunho local (iOS 17, sem dependência
  externa, integra com `@Observable`).
- Nada de token em `UserDefaults` — credencial vai no **Keychain**.

### 2.5 A pergunta do backend

A escolha de backend **não muda nada do que está acima** — é justamente por
isso que a camada de repositório vem primeiro. Quando a decisão for tomada,
escrever `RemotePartnerRepository` é trabalho localizado.

Vale registrar o que o produto vai exigir de qualquer opção: contas,
geolocalização com consulta por raio, tempo real para convites e chat, e push
notification. Um app de encontrar parceiro **perto agora** vive ou morre na
notificação: sem push, o convite chega quando a pessoa já foi treinar.

---

## Parte 3 — Plano de migração

Incremental. Cada fase é uma branch, um PR e uma tag — o app fica funcionando
o tempo todo. Nenhuma fase é um "grande refactor".

| Fase | Entrega | Tag |
|------|---------|-----|
| 1 | Mover arquivos para as pastas de camada, sem mudar código | `v0.2.0` |
| 2 | `Sport` enum + separar `Palette` de estilo de esporte | `v0.3.0` |
| 3 | `Domain` sem SwiftUI; `distanceInMeters`; `sample` sai do modelo | `v0.4.0` |
| 4 | Protocolos de repositório + implementação em memória | `v0.5.0` |
| 5 | `FeedViewModel`; quebrar `FeedView` | `v0.6.0` |
| 6a | ViewModel de Profile; quebrar `ProfileView` e `EditProfileView` | `v0.7.0` |
| 6b | ViewModel de Portfolio; quebrar `PartnerPortfolioView` | `v0.7.0` |
| 7 | `AppSession` + onboarding que coleta de verdade + SwiftData | `v0.8.0` |

A cada fase que quebra uma View, a baseline do SwiftLint encolheu — 9, 6, 3,
0. Na fase 6b ela foi apagada, e o `--strict` passou a valer sem rede.

**A fase 1 é de graça e destrava todas as outras** — é só mover arquivo, com
o XcodeGen regerando o projeto sozinho.
