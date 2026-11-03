import SwiftUI
import SwiftData
import GasCoKit

struct MainView: View {
    let model: MonitorModel
    @State private var showsPicker = false

    private var reading: SensorReading? { model.reading }
    private var isStale: Bool { reading?.isStale() ?? true }
    private var level: DangerLevel { reading?.worstLevel ?? .safe }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ConnectionBadge(state: model.state)
                    if !isStale, level == .danger {
                        AlarmBanner(reading: reading)
                    }
                    HStack(spacing: 16) {
                        ForEach(SensorKind.allCases) { kind in
                            SensorGaugeView(kind: kind, reading: reading, lineWidth: 14)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .padding(12)
                                .background(.white.opacity(0.06), in: .rect(cornerRadius: 24))
                        }
                    }
                    if let reading {
                        Label {
                            Text("Ostatni odczyt \(reading.timestamp, style: .relative) temu")
                        } icon: {
                            Image(systemName: isStale ? "clock.badge.exclamationmark" : "clock")
                        }
                        .font(.footnote)
                        .foregroundStyle(isStale ? Color.staleLevel : .secondary)
                    }
                    HistoryChartView()
                }
                .padding()
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Gaz / CO")
            .toolbar {
                Button("Czujnik", systemImage: "sensor.tag.radiowaves.forward") { showsPicker = true }
            }
            .sheet(isPresented: $showsPicker) {
                SensorPickerView(connection: model.connection)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundGradient: LinearGradient {
        let tint = isStale ? Color.staleLevel : level.color
        return LinearGradient(colors: [tint.opacity(0.35), .gasCoBackground, .gasCoBackground],
                              startPoint: .top, endPoint: .bottom)
    }
}

private struct ConnectionBadge: View {
    let state: SensorConnectionState

    var body: some View {
        Label(state.title, systemImage: state.symbolName)
            .font(.subheadline.weight(.medium))
            .symbolEffect(.variableColor.iterative, isActive: !state.isConnected)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: .capsule)
            .foregroundStyle(state.isConnected ? Color.safeLevel : .secondary)
    }
}

private struct AlarmBanner: View {
    let reading: SensorReading?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "light.beacon.max.fill")
                .font(.largeTitle)
                .symbolEffect(.pulse)
            VStack(alignment: .leading) {
                Text("ALARM")
                    .font(.title2.bold())
                Text("Przewietrz pomieszczenie i opuść je, jeśli poziom nie spada.")
                    .font(.subheadline)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding()
        .background(Color.dangerLevel.gradient, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Normal") {
    MainView(model: .preview())
        .modelContainer(for: ReadingRecord.self, inMemory: true)
}

#Preview("Alarm") {
    MainView(model: .preview(.previewAlarm))
        .modelContainer(for: ReadingRecord.self, inMemory: true)
}
