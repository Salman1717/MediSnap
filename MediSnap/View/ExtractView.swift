//
//  ExtractView.swift
//  MediSnap
//
//  Created by Aaseem Mhaskar on 20/09/25.
//

// ExtractView.swift
import SwiftUI
import PhotosUI

struct ExtractView: View {
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    // OCR + extraction state
    @State private var prescriptionText: String = ""
    @State private var meds: [Medication] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Extract Prescription")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)

            HStack(spacing: 16) {
                // Camera Button
                Button(action: { showCamera = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Camera")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
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
                    .shadow(radius: 2)
                }
            }
            .padding(.horizontal)

            // show selected image
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 240)
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 240)
                    .overlay(Text("No image selected").foregroundColor(.secondary))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            // Controls: run OCR & extract manually or automatically on selection
            HStack(spacing: 12) {
                Button(action: {
                    Task { await runOcrAndExtract() }
                }) {
                    HStack {
                        if isLoading { ProgressView().scaleEffect(0.9) }
                        Text(isLoading ? "Processing..." : "Run OCR & Extract")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(selectedImage == nil || isLoading)

                Button(action: {
                    // clear
                    selectedImage = nil
                    prescriptionText = ""
                    meds = []
                    errorMessage = nil
                }) {
                    Text("Clear")
                        .frame(width: 88, height: 44)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            if !prescriptionText.isEmpty {
                GroupBox("OCR Text") {
                    ScrollView {
                        Text(prescriptionText)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .padding(6)
                    }
                    .frame(height: 120)
                }
                .padding(.horizontal)
            }

            if let err = errorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            // List of extracted meds
            List {
                if meds.isEmpty {
                    Text("No medications extracted yet").foregroundColor(.secondary)
                } else {
                    ForEach(meds) { med in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(med.name).font(.headline)
                                Spacer()
                                if med.uncertain || (med.confidence ?? 0) < 0.7 {
                                    Text("Check")
                                        .font(.caption2)
                                        .padding(6)
                                        .background(Color.yellow.opacity(0.3))
                                        .cornerRadius(6)
                                }
                            }
                            Text("Dosage: \(med.dosage ?? "-")  •  Freq: \(med.frequency ?? "-")  •  Dur: \(med.duration ?? "-")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let raw = med.originalText {
                                Text("OCR: \(raw)").font(.caption2).foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    // optional: auto-run OCR+extract
                    await runOcrAndExtract()
                }
            }
        }
        .onChange(of: selectedImage) { new in
            // optional: auto-run when camera picks an image
            if new != nil {
                Task { await runOcrAndExtract() }
            }
        }
    }

    // MARK: - OCR + Gemini extraction
    func runOcrAndExtract() async {
        guard let img = selectedImage else { return }
        isLoading = true
        errorMessage = nil
        prescriptionText = ""
        meds = []

        do {
            // 1) OCR
            let ocr = try await OCRHelper.recognizeText(from: img)
            prescriptionText = ocr

            // 2) Gemini extraction (text -> Medication[])
            let extracted = try await GeminiService.shared.extractMeds(from: ocr)
            meds = extracted
        } catch {
            if let ns = error as NSError?,
               let preview = ns.userInfo["modelResponsePreview"] as? String {
                errorMessage = "Decode error. Model preview:\n\n\(preview)"
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

// Existing ImagePicker wrapper (camera)
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
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

// Preview
#Preview {
    ExtractView()
}
