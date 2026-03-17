import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Measurement.date) var measurements: [Measurement]
    @Environment(\.modelContext) private var context
    @State private var showScanner = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 16) {

                // Заголовок
                VStack(alignment: .leading, spacing: 4) {
                    Text("Давление")
                        .font(.largeTitle.bold())
                    Text("За последние 7 дней")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)

                // График
                ChartView(measurements: measurements)
                    .frame(height: 260)
                    .padding(.horizontal)

                // Последнее измерение
                if let last = measurements.last {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Последнее")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(last.systolic) / \(last.diastolic)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text(last.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Индикатор нормы
                        Circle()
                            .fill(statusColor(last.systolic))
                            .frame(width: 16, height: 16)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Spacer()
            }

            // Кнопка "+"
            Button {
                showScanner = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.red.gradient)
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            if measurements.isEmpty {
                context.insert(Measurement(systolic: 120, diastolic: 80, pulse: 72))
                context.insert(Measurement(systolic: 135, diastolic: 88, pulse: 78))
                context.insert(Measurement(systolic: 118, diastolic: 76, pulse: 65))
            }
        }

        .sheet(isPresented: $showScanner) {
            // ScannerView() — подключим позже
            Text("Камера — скоро")
                .font(.title2)
        }
    }

    func statusColor(_ systolic: Int) -> Color {
        switch systolic {
        case ..<120: return .green
        case 120..<140: return .yellow
        default: return .red
        }
    }
}
