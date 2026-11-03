import SwiftUI
import SwiftData
import Charts
import GasCoKit

struct HistoryChartView: View {
    enum Range: Int, CaseIterable, Identifiable {
        case hour = 1, sixHours = 6, day = 24
        var id: Int { rawValue }
        var title: String { "\(rawValue) h" }
    }

    @State private var range: Range = .hour
    @Query(sort: \ReadingRecord.timestamp) private var records: [ReadingRecord]

    private var visible: [ReadingRecord] {
        let start = Date.now.addingTimeInterval(-Double(range.rawValue) * 3600)
        return records.filter { $0.timestamp >= start }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Historia")
                    .font(.headline)
                Spacer()
                Picker("Zakres", selection: $range) {
                    ForEach(Range.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }
            if visible.isEmpty {
                ContentUnavailableView("Brak danych", systemImage: "chart.xyaxis.line",
                                       description: Text("Odczyty pojawią się po połączeniu z czujnikiem."))
                    .frame(height: 180)
            } else {
                chart
            }
        }
        .padding()
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 20))
    }

    private var chart: some View {
        Chart {
            RectangleMark(yStart: .value("", DangerLevel.dangerThreshold), yEnd: .value("", 100))
                .foregroundStyle(Color.dangerLevel.opacity(0.12))
            RectangleMark(yStart: .value("", DangerLevel.warningThreshold), yEnd: .value("", DangerLevel.dangerThreshold))
                .foregroundStyle(Color.warningLevel.opacity(0.10))
            ForEach(visible) { record in
                LineMark(x: .value("Czas", record.timestamp), y: .value("Poziom", record.co))
                    .foregroundStyle(by: .value("Czujnik", SensorKind.co.title))
                LineMark(x: .value("Czas", record.timestamp), y: .value("Poziom", record.gas))
                    .foregroundStyle(by: .value("Czujnik", SensorKind.gas.title))
            }
        }
        .chartForegroundStyleScale([SensorKind.co.title: Color.coAccent, SensorKind.gas.title: Color.gasAccent])
        .chartYScale(domain: 0...100)
        .chartYAxis { AxisMarks(values: [0, 50, 70, 100]) }
        .frame(height: 180)
    }
}
