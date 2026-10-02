import UIKit

/// Encolhe a foto no aparelho antes dela ir para qualquer lugar
/// (docs/PRODUTO.md §10.1).
///
/// Uma foto de câmera tem 3 a 5 MB; depois daqui, perto de 300 KB. É a
/// defesa contra o limite de Storage do plano gratuito do Supabase (§7).
enum PhotoCompressor {
    static let maxDimension: CGFloat = 1600
    static let quality: CGFloat = 0.7

    static func jpegData(from image: UIImage) -> Data? {
        let lado = max(image.size.width, image.size.height)
        guard lado > 0 else { return nil }

        let escala = min(1, maxDimension / lado)
        let tamanho = CGSize(
            width: (image.size.width * escala).rounded(),
            height: (image.size.height * escala).rounded()
        )

        // Escala 1: o tamanho pedido é em pixels, não em pontos de tela —
        // senão um iPhone 3x geraria uma imagem três vezes maior.
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        let reduzida = UIGraphicsImageRenderer(size: tamanho, format: formato).image { _ in
            image.draw(in: CGRect(origin: .zero, size: tamanho))
        }
        return reduzida.jpegData(compressionQuality: quality)
    }
}
