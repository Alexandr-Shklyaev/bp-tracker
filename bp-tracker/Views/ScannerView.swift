import SwiftUI
import AVFoundation
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var recognizedText = "Наведи камеру на дисплей тонометра"
    @State private var detectedReading: (systolic: Int, diastolic: Int)? = nil
    @State private var isConfirmed = false

    var body: some View {
        ZStack {
            // Превью камеры — занимает весь экран
            CameraPreviewView(onFrame: handleFrame)
                .ignoresSafeArea()

            // Затемнение по краям — фокусируем внимание на центре
            VStack {
                Spacer()

                // Рамка прицела
                RoundedRectangle(cornerRadius: 12)
                    .stroke(detectedReading != nil ? Color.green : Color.white,
                            lineWidth: 2)
                    .frame(width: 280, height: 120)

                Spacer()
            }

            // UI поверх камеры
            VStack {
                // Заголовок
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Сканирование")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    // для симметрии
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()

                Spacer()

                // Результат OCR внизу
                VStack(spacing: 16) {
                    if let reading = detectedReading {
                        // Найдено! Показываем результат
                        VStack(spacing: 8) {
                            Text("Обнаружено")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(reading.systolic) / \(reading.diastolic)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("мм рт. ст.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        Button {
                            saveMeasurement(reading)
                        } label: {
                            Text("Сохранить")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)

                    } else {
                        // Ещё не нашли
                        Text(recognizedText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .background(.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding()
            }
        }
    }

    // Этот метод вызывается на каждый кадр с камеры
    // Как callback в OpenCV VideoCapture
    private func handleFrame(_ image: UIImage) {
        let ocr = OCRService()
        if let reading = ocr.recognize(image: image) {
            DispatchQueue.main.async {
                self.detectedReading = reading
            }
        }
    }

    private func saveMeasurement(_ reading: (systolic: Int, diastolic: Int)) {
        let measurement = Measurement(
            systolic: reading.systolic,
            diastolic: reading.diastolic
        )
        context.insert(measurement)
        dismiss()
    }
}

