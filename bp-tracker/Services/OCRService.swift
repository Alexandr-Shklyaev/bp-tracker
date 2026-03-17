import Vision
import UIKit

class OCRService {
    
    // VNRecognizeTextRequest — это как запуск inference в CV-пайплайне
    // Apple Vision запускает модель распознавания текста on-device
    private let request: VNRecognizeTextRequest
    
    init() {
        request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate    // точнее, но чуть медленнее
        request.recognitionLanguages = ["en-US"] // цифры — язык не важен, но en быстрее
        request.usesLanguageCorrection = false   // отключаем — нам нужны цифры, не слова
    }
    
    // Принимает UIImage (кадр с камеры), возвращает распознанное давление или nil
    func recognize(image: UIImage) -> (systolic: Int, diastolic: Int)? {
        guard let cgImage = image.cgImage else { return nil }
        
        // VNImageRequestHandler — как DataLoader в PyTorch, подготавливает данные для модели
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Vision error: \(error)")
            return nil
        }
        
        // Собираем весь распознанный текст в одну строку
        guard let results = request.results else { return nil }
        let fullText = results
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
        
        print("OCR raw text: \(fullText)") // для дебага, потом уберём
        
        return parseBloodPressure(from: fullText)
    }
    
    // Парсим текст — ищем паттерн типа "120/80" или "120 80"
    private func parseBloodPressure(from text: String) -> (systolic: Int, diastolic: Int)? {
        
        // Regex паттерн: одно число / другое число
        // \d{2,3} — два или три цифры (80–199)
        let pattern = #"(\d{2,3})\s*[/\\|]\s*(\d{2,3})"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
              ) else {
            // Пробуем альтернативный паттерн — два числа рядом без разделителя
            return parseTwoNumbers(from: text)
        }
        
        // Извлекаем группы из regex match
        guard let r1 = Range(match.range(at: 1), in: text),
              let r2 = Range(match.range(at: 2), in: text),
              let systolic = Int(text[r1]),
              let diastolic = Int(text[r2]) else { return nil }
        
        return validate(systolic: systolic, diastolic: diastolic)
    }
    
    // Запасной вариант — тонометр показывает числа отдельно
    private func parseTwoNumbers(from text: String) -> (systolic: Int, diastolic: Int)? {
        let numbers = text
            .components(separatedBy: .whitespacesAndNewlines)
            .compactMap { Int($0) }
            .filter { $0 >= 40 && $0 <= 250 }
        
        guard numbers.count >= 2 else { return nil }
        return validate(systolic: numbers[0], diastolic: numbers[1])
    }
    
    // Валидация — физиологически невозможные значения отбрасываем
    // Это как post-processing в CV: убираем ложные срабатывания
    private func validate(systolic: Int, diastolic: Int) -> (systolic: Int, diastolic: Int)? {
        guard systolic >= 70 && systolic <= 250 else { return nil }
        guard diastolic >= 40 && diastolic <= 150 else { return nil }
        guard systolic > diastolic else { return nil } // систола всегда выше
        return (systolic, diastolic)
    }
}

