import PhotosUI
import SwiftUI

/// O caminho inteiro de registrar uma foto: escolher entre câmera e
/// galeria, abrir a escolhida e comprimir o resultado.
///
/// É um modificador para o Feed e o botão da Dynamic Island usarem o mesmo
/// fluxo — basta ligar `isPresented`.
struct WorkoutPhotoCapture: ViewModifier {
    @Binding var isPresented: Bool
    /// Recebe o JPEG já comprimido.
    var onPhoto: (Data) -> Void

    @State private var askSource = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var picked: PhotosPickerItem?

    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, pedido in
                guard pedido else { return }
                isPresented = false
                // Sem câmera (simulador), direto para a galeria, em vez de
                // oferecer uma opção que não funciona.
                if CameraPicker.isAvailable {
                    askSource = true
                } else {
                    showLibrary = true
                }
            }
            .confirmationDialog(
                "Registrar foto do treino",
                isPresented: $askSource,
                titleVisibility: .visible
            ) {
                Button("Tirar foto") { showCamera = true }
                Button("Escolher da galeria") { showLibrary = true }
                Button("Cancelar", role: .cancel) {}
            }
            .photosPicker(isPresented: $showLibrary, selection: $picked, matching: .images)
            .onChange(of: picked) { _, item in
                guard let item else { return }
                picked = nil
                Task {
                    guard let dados = try? await item.loadTransferable(type: Data.self),
                          let imagem = UIImage(data: dados)
                    else { return }
                    deliver(imagem)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { imagem in deliver(imagem) }
                    .ignoresSafeArea()
            }
    }

    private func deliver(_ image: UIImage) {
        guard let jpeg = PhotoCompressor.jpegData(from: image) else { return }
        onPhoto(jpeg)
    }
}

extension View {
    func workoutPhotoCapture(isPresented: Binding<Bool>, onPhoto: @escaping (Data) -> Void) -> some View {
        modifier(WorkoutPhotoCapture(isPresented: isPresented, onPhoto: onPhoto))
    }
}
