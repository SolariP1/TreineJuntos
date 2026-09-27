import Testing
@testable import TreinaJunto

@Suite("Domínio · WorkoutPartner")
struct WorkoutPartnerTests {
    @Test("A inicial vem da primeira letra do nome")
    func initialsUseFirstLetter() {
        #expect(Fixtures.partner(name: "Marina").initials == "M")
    }

    @Test("O gradiente nunca estoura o índice do tema")
    func gradientIndexWrapsAround() {
        // Um índice acima do número de gradientes precisa dar a volta em vez
        // de quebrar — o backend ainda não garante a faixa do valor.
        _ = Fixtures.partner(gradientIndex: 999).gradient
    }

    @Test("Dois parceiros com os mesmos dados continuam sendo distintos")
    func identityIsPerInstance() {
        let um = Fixtures.partner()
        let outro = Fixtures.partner()
        #expect(um.id != outro.id)
    }
}
