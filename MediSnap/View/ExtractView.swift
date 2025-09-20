import SwiftUI
import PhotosUI
import SwiftfulLoadingIndicators

struct ExtractView: View {
    @StateObject private var vm = ExtractViewModel()
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
                VStack(spacing: 20) {
                    Text("Extract Prescription")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                        .shadow(radius: 5)

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
                                .overlay(Text("Capture or Select Prescription Image")
                                    .foregroundColor(.white)
                                    .font(.headline))
                                .cornerRadius(16)
                                .padding(.horizontal)
                        }
                    }
                    .animation(.easeInOut, value: vm.selectedImage)

                    HStack(spacing: 16) {
                        Button(action: { vm.showCamera = true }) {
                            Label("Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(gradientBackground)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }

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
                    .padding(.horizontal)

                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    Spacer()

                    // Always at bottom
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
                .background(
                    gradientBackground
                        .ignoresSafeArea()
                )
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

                // Loader overlay
                if vm.isLoading {
                    ZStack {
                        LoadingIndicator(animation: .doubleHelix,size: .large, speed: .slow)
                    }
                }
            }
        }
    }
}


#Preview {
    ExtractView()
}
