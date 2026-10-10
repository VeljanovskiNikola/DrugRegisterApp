import AVFoundation
import SwiftUI
import UIKit

/// Scans the barcode on a drug package. When the camera cannot be used (simulator,
/// older device, no permission), the user can type the number printed under the barcode.
struct BarcodeScannerSheet: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var cameraAllowed: Bool?
    @State private var typedCode = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingMedium) {
                camera
                manualEntry
            }
            .padding(.spacingMedium)
            .background(.appBackground)
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Asks for camera access the first time. Answers at once when the user already chose.
            .task { cameraAllowed = await AVCaptureDevice.requestAccess(for: .video) }
        }
    }

    @ViewBuilder
    private var camera: some View {
        switch cameraAllowed {
        case nil:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case true? where BarcodeScannerView.isAvailable:
            BarcodeScannerView { finish(with: $0) }
                .clipShape(.rect(cornerRadius: .cornerRadiusLarge))
                .overlay(alignment: .bottom) {
                    Text("Point the camera at the barcode on the package.")
                        .font(.appSubheadline)
                        .padding(.horizontal, .spacingMedium)
                        .padding(.vertical, .spacingSmall)
                        .background(.regularMaterial, in: .capsule)
                        .padding(.spacingMedium)
                }
        default:
            ContentUnavailableView {
                Label("Scanning is not available", systemImage: "barcode.viewfinder")
            } description: {
                Text("Allow camera access in Settings, or type the number under the barcode.")
            } actions: {
                if cameraAllowed == false {
                    Button("Open Settings") { openAppSettings() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private var manualEntry: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text("Or type the number under the barcode.")
                .font(.appCaption)
                .foregroundStyle(.appSecondaryText)
            HStack(spacing: .spacingSmall) {
                TextField("EAN number", text: $typedCode)
                    .keyboardType(.numberPad)
                    .textContentType(.none)
                    .font(.appBody.monospacedDigit())
                    .padding(.spacingSmall)
                    .background(.appCardBackground, in: .rect(cornerRadius: .cornerRadiusMedium))
                Button("Search") { finish(with: typedCode) }
                    .buttonStyle(.borderedProminent)
                    .disabled(EAN.normalized(typedCode) == nil)
            }
        }
    }

    private func finish(with code: String) {
        onScan(code)
        dismiss()
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

#if DEBUG
#Preview {
    Text("Search")
        .sheet(isPresented: .constant(true)) {
            BarcodeScannerSheet { _ in }
        }
}
#endif
