/// Em que pé está o carregamento de uma tela.
///
/// Vocabulário compartilhado entre as features: enquanto os dados vinham de
/// constantes no código, "carregando" e "falhou" não existiam. Com
/// repositórios assíncronos passam a existir sempre — e uma tela que não
/// trata os dois é uma tela que trava ou mente.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case let .loaded(value) = self {
            return value
        }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case let .failed(message) = self {
            return message
        }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
