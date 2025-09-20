//
//  ExtractView.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 20/09/25.
//

import SwiftUI
import PhotosUI

struct ExtractView: View {
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("Extract Prescription")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Buttons
            HStack(spacing: 20) {
                
                // Camera Button
                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Camera")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
                
                // Gallery Button
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.fill.on.rectangle.fill")
                        Text("Gallery")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
            }
            .padding(.horizontal, 24)
            
            // Show selected/captured image
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                    .cornerRadius(12)
                    .padding()
            } else {
                Text("No image selected")
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
        }
        .onChange(of: selectedItem) {_, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
}

// MARK: - UIKit Image Picker Wrapper for Camera
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ExtractView()
}
