/// Modalidade de treino.
///
/// O `rawValue` é a chave de armazenamento — é o que vai para o servidor e
/// para o disco, então mudar um deles quebra dado já gravado. O texto que o
/// usuário lê fica em `Sport.label`, na camada de apresentação.
enum Sport: String, CaseIterable, Codable, Hashable, Sendable {
    case corrida
    case musculacao
    case funcional
    case ciclismo
    case yoga
    case natacao
}
