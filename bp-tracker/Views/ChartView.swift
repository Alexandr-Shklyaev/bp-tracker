import SwiftUI
import Charts

struct ChartView: View {
    let measurements: [Measurement]

    var weekData: [Measurement] {
        let week = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return measurements.filter { $0.date >= week }
    }

    var body: some View {
        if weekData.isEmpty {
            ContentUnavailableView(
                "Нет данных",
                systemImage: "heart.text.square",
                description: Text("Нажми + чтобы добавить первое измерение")
            )
        } else {
            Chart {
                ForEach(weekData) { item in
                    LineMark(
                        x: .value("Дата", item.date),
                        y: .value("Систола", item.systolic)
                    )
                    .foregroundStyle(.red)
                    .symbol(.circle)

                    LineMark(
                        x: .value("Дата", item.date),
                        y: .value("Диастола", item.diastolic)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                }

                RuleMark(y: .value("Норма", 120))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("норма")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
            }
            .chartYScale(domain: 40...200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) {
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
    }
}

