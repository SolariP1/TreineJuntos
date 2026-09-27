/// Uma conquista exibida no perfil: ícone, texto e a cor que a acompanha.
///
/// Antes isto era a tupla `(String, String, SportStyle)`. O `SportStyle` ali
/// era engano: "Madrugador" não é um esporte, só precisava ser rosa. Agora a
/// medalha carrega uma cor e pronto.
struct Badge: Hashable {
    let symbol: String
    let label: String
    let ramp: ColorRamp
}
