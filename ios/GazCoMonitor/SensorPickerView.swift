import SwiftUI
import GasCoKit

struct SensorPickerView: View {
    let connection: SensorConnection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let name = connection.rememberedSensorName, !name.isEmpty {
                    Section("Zapamiętany czujnik") {
                        LabeledContent(name, value: connection.state.title)
                        Button("Zapomnij czujnik", role: .destructive) {
                            connection.forgetSensor()
                        }
                    }
                }
                Section {
                    ForEach(connection.discovered) { sensor in
                        Button {
                            connection.connect(to: sensor)
                            dismiss()
                        } label: {
                            LabeledContent(sensor.name) {
                                Label("\(sensor.rssi) dBm", systemImage: "wifi")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Dostępne czujniki")
                        Spacer()
                        if case .scanning = connection.state { ProgressView() }
                    }
                } footer: {
                    if connection.discovered.isEmpty {
                        Text("Upewnij się, że czujnik jest włączony i w zasięgu.")
                    }
                }
            }
            .navigationTitle("Czujnik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") {
                        if !connection.state.isConnected { connection.start() }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Skanuj", systemImage: "arrow.clockwise") { connection.scanForSensors() }
                }
            }
            .task { connection.scanForSensors() }
        }
    }
}
