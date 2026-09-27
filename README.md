# TreinaJunto

App iOS para encontrar parceiros de treino por perto — quem está disponível,
em qual esporte e a que distância.

SwiftUI · iOS 17+ · projeto gerado por XcodeGen

---

## Começando

O `.xcodeproj` **não** está versionado: ele é gerado a partir do `project.yml`.

```bash
brew install xcodegen swiftlint swiftformat
git clone https://github.com/SolariP1/TreineJuntos.git
cd TreineJuntos
xcodegen generate
./scripts/setup-hooks.sh
open TreinaJunto.xcodeproj
```

Sempre que mexer em `project.yml` (ou adicionar arquivo fora do Xcode), rode
`xcodegen generate` de novo.

## Testes

```bash
xcodebuild test -project TreinaJunto.xcodeproj -scheme TreinaJunto \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Os testes ficam em `Tests/TreinaJuntoTests/`, agrupados por componente:

- `Domain/` — regras puras dos modelos
- `Features/<Feature>/` — um diretório por feature do app
- `Support/` — fixtures compartilhadas

## Estrutura

```
project.yml            fonte da verdade do projeto Xcode
TreinaJunto/           código do app
Tests/                 testes automatizados
docs/releases/         nota de cada versão
.githooks/             validação de commit e formatação
.github/workflows/     CI
CONVENTIONS.md         padrões do projeto — leia antes de commitar
TODO.md                próximos passos
```

## Contribuindo

Leia [CONVENTIONS.md](CONVENTIONS.md) antes do primeiro commit: formato das
mensagens, tags de versão, nomes de branch e o que não entra no repositório.
