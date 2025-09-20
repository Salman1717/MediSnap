//
//  ExtractView.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import SwiftUI
import PhotosUI

struct ExtractView: View {
    @StateObject private var vm = ExtractViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Extract Prescription")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                HStack(spacing: 16) {
                    Button(action: { vm.showCamera = true }) {
                        Label("Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Label("Gallery", systemImage: "photo.fill.on.rectangle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                if let image = vm.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 240)
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 240)
                        .overlay(Text("No image selected").foregroundColor(.secondary))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                if vm.isLoading {
                    ProgressView("Extracting...")
                        .padding()
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                NavigationLink("Edit Medications", destination: EditableMedicationsView(vm: vm))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Prescription OCR")
            .sheet(isPresented: $vm.showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $vm.selectedImage)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        vm.selectedImage = uiImage
                        await vm.processImage(uiImage)
                    }
                }
            }
            .onChange(of: vm.selectedImage) { newImage in
                if let img = newImage {
                    Task { await vm.processImage(img) }
                }
            }
        }
    }
}


// MARK: - Preview
#Preview {
    ExtractView()
}
