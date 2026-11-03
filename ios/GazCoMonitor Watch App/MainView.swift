import SwiftUI
import GasCoKit

struct MainView: View {
    let model: MonitorModel

    var body: some View {
        TabView {
            SummaryPage(model: model)
            ForEach(SensorKind.allCases) { kind in
                SensorPage(kind: kind, reading: model.reading)
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview("Normal") {
    MainView(model: .preview())
}

#Preview("Alarm") {
    MainView(model: .preview(.previewAlarm))
}
