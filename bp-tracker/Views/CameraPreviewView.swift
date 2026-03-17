//
//  CameraPreviewView.swift
//  bp-tracker
//
//  Created by Alexandr Shklyaev on 17.03.2026.
//

import SwiftUI
import AVFoundation

// UIViewRepresentable — мост между UIKit и SwiftUI
// Нам нужен UIKit здесь потому что AVFoundation работает с UIView, не с SwiftUI View
struct CameraPreviewView: UIViewRepresentable {
    let onFrame: (UIImage) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        context.coordinator.setupCamera(in: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFrame: onFrame)
    }

    // Coordinator — паттерн SwiftUI для делегатов UIKit
    // Как callback-класс
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let onFrame: (UIImage) -> Void
        var session: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?

        // Throttle — не гоним OCR на каждый кадр (60fps избыточно)
        // Запускаем раз в секунду — достаточно для статичного дисплея тонометра
        private var lastProcessed = Date.distantPast
        private let interval: TimeInterval = 1.0

        init(onFrame: @escaping (UIImage) -> Void) {
            self.onFrame = onFrame
        }

        func setupCamera(in view: UIView) {
            let session = AVCaptureSession()
            session.sessionPreset = .photo

            // Получаем задную камеру
            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
            let input = try? AVCaptureDeviceInput(device: device) else {
                print("Камера недоступна")
                return
            }

            session.addInput(input)

            // Output — получаем сырые кадры
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "camera.queue")
            )
            session.addOutput(output)

            // PreviewLayer — отображаем превью в UIView
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds

            DispatchQueue.main.async {
                view.layer.addSublayer(previewLayer)
                previewLayer.frame = view.bounds
            }

            self.session = session
            self.previewLayer = previewLayer

            // Запускаем сессию в фоновом потоке
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }

        // Вызывается на каждый кадр — как frame callback в OpenCV
        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            // Throttle — пропускаем кадры, обрабатываем раз в секунду
            let now = Date()
            guard now.timeIntervalSince(lastProcessed) >= interval else { return }
            lastProcessed = now

            // CMSampleBuffer → UIImage
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            let image = UIImage(cgImage: cgImage)

            onFrame(image)
        }
    }
}
