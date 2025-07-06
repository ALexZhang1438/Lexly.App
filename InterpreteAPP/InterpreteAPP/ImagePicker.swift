//
//  ImagePicker.swift
//  InterpreteAPP
//
//  Created by Alex Zhang on 29/6/25.
//

import SwiftUI
import PhotosUI

// MARK: - Selector de Imagen Moderno
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No necesita actualización
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error cargando imagen: \(error.localizedDescription)")
                        return
                    }
                    
                    if let uiImage = image as? UIImage {
                        // Optimizar imagen antes de asignar
                        self.parent.image = self.optimizarImagen(uiImage)
                    }
                }
            }
        }
        
        private func optimizarImagen(_ imagen: UIImage) -> UIImage {
            let maxSize = Config.API.maxImageSize
            let compressionQuality = Config.API.imageCompressionQuality

            // Validar tamaño original
            guard imagen.size.width > 0, imagen.size.height > 0 else {
                print("❌ Imagen original inválida")
                return imagen
            }

            // Redimensionar si es necesario
            let imagenRedimensionada: UIImage
            if imagen.size.width > maxSize || imagen.size.height > maxSize {
                let ratio = min(maxSize / imagen.size.width, maxSize / imagen.size.height)
                let newSize = CGSize(width: imagen.size.width * ratio, height: imagen.size.height * ratio)

                if newSize.width.isNaN || newSize.height.isNaN || newSize.width <= 0 || newSize.height <= 0 {
                    print("❌ Tamaño de redimensionamiento inválido: \(newSize)")
                    return imagen
                }

                UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
                imagen.draw(in: CGRect(origin: .zero, size: newSize))
                imagenRedimensionada = UIGraphicsGetImageFromCurrentImageContext() ?? imagen
                UIGraphicsEndImageContext()
            } else {
                imagenRedimensionada = imagen
            }

            // Comprimir
            guard let data = imagenRedimensionada.jpegData(compressionQuality: compressionQuality),
                  let imagenComprimida = UIImage(data: data),
                  imagenComprimida.size.width > 0, imagenComprimida.size.height > 0 else {
                print("❌ Imagen comprimida inválida")
                return imagenRedimensionada
            }

            return imagenComprimida
        }

    }
}

// MARK: - Vista Previa de Imagen
struct ImagePreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    let onConfirm: () -> Void
    
    @ViewBuilder
    var body: some View {
        NavigationView {
            VStack {
                if image.size.width > 0 && image.size.height > 0 {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(12)
                        .padding()
                } else {
                    Text("⚠️ La imagen no se pudo cargar")
                        .foregroundColor(.red)
                        .padding()
                }
                
                HStack(spacing: 20) {
                    Button("Cancelar") {
                        onDismiss()
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Analizar") {
                        onConfirm()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Vista Previa")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ImagePreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onDismiss: {},
        onConfirm: {}
    )
}
