import SwiftUI
import PhotosUI
import SwiftfulLoadingIndicators

struct ExtractView: View {
    @StateObject private var vm = ExtractViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedItem: PhotosPickerItem?

    var gradientBackground: LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.7), Color.teal.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                mainContent
                    .background(gradientBackground.ignoresSafeArea())
                    .sheet(isPresented: $vm.showCamera) {
                        ImagePicker(sourceType: .camera, selectedImage: $vm.selectedImage)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        handleGallerySelection(newItem)
                    }
                    .onChange(of: vm.selectedImage) { _, newImage in
                        handleCameraImage(newImage)
                    }

                if vm.isLoading {
                    loaderOverlay
                }
            }
            .navigationTitle("Prescription OCR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Components

    private var mainContent: some View {
        VStack(spacing: 20) {
            Text("Extract Prescription")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)
                .shadow(radius: 5)

            prescriptionImageView

            HStack(spacing: 16) {
                cameraButton
                galleryButton
            }
            .padding(.horizontal)

            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Spacer()

            NavigationLink(destination: EditableMedicationsView(vm: vm)) {
                Text("Edit Medications")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gradientBackground)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private var prescriptionImageView: some View {
        Group {
            if let image = vm.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 260)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 260)
                    .overlay(
                        Text("Capture or Select Prescription Image")
                            .foregroundColor(.white)
                            .font(.headline)
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: vm.selectedImage)
    }

    private var cameraButton: some View {
        Button(action: { vm.showCamera = true }) {
            Label("Camera", systemImage: "camera.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(gradientBackground)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }

    private var galleryButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            Label("Gallery", systemImage: "photo.fill.on.rectangle.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(gradientBackground)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }

    private var loaderOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                LoadingIndicator(
                    animation: .doubleHelix,
                    color: .blue,
                    size: .medium,
                    speed: .fast
                )
                
                Text("Extracting...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }


    // MARK: - Handlers
    private func handleGallerySelection(_ newItem: PhotosPickerItem?) {
        Task {
            guard let item = newItem else { return }
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                vm.selectedImage = uiImage
                await vm.processImage(uiImage)
            }
        }
    }

    private func handleCameraImage(_ newImage: UIImage?) {
        Task {
            guard let img = newImage else { return }
            await vm.processImage(img)
        }
    }
}

#Preview {
    ExtractView()
}
