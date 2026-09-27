# Testes por feature

Uma pasta por feature do app, espelhando a organização do código em
`TreinaJunto/Features/`. Quando uma feature ganha um ViewModel ou um
repositório, o teste dele nasce aqui.

Convenção de nome do suite: `@Suite("<Feature> · <Componente>")`, para o
relatório do Xcode e do CI agrupar sozinho.

| Pasta        | Cobre                                                      |
|--------------|------------------------------------------------------------|
| `Feed/`      | listagem de parceiros, filtros, disponibilidade            |
| `Perfil/`    | perfil próprio, edição, portfólio público                  |
| `Onboarding/`| criação de conta e primeiro perfil                          |
| `Convites/`  | saldo de convites de academia e consumo por treino          |

Testes de regra pura que não pertencem a nenhuma feature ficam em `../Domain/`.
Construtores de objetos de teste ficam em `../Support/Fixtures.swift` — nunca
duplicados dentro de um arquivo de teste.
