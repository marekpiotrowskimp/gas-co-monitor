import SwiftUI
import SwiftData
import GasCoKit

@main
struct GasCoMonitorApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: MonitorModel
    private let container: ModelContainer
    private let recorder: HistoryRecorder
    private let notifier = AlarmNotifier()
    private let widgetReloader = WidgetReloader()
    private let relay = ReadingRelay()

    // Everything that must work after a background relaunch by Core Bluetooth state restoration
    // is set up here: no window (and no `.task`) is created in that case.
    init() {
        let container = try! ModelContainer(for: ReadingRecord.self)
        self.container = container
        self.recorder = HistoryRecorder(context: container.mainContext)
        let model = MonitorModel(connection: SensorConnection(restoreIdentifier: "GasCoMonitor.central"))
        _model = State(initialValue: model)

        model.onNewReading = { [recorder, notifier, widgetReloader, relay] reading in
            widgetReloader.handle(reading)
            recorder.record(reading)
            notifier.handle(reading)
            relay.send(reading)
        }
        relay.activate()
        if !Self.isMockLaunch {
            model.start()
        }
    }

    private static var isMockLaunch: Bool {
        #if DEBUG
        CommandLine.arguments.contains("-mockAlarm") || CommandLine.arguments.contains("-mockReading")
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainView(model: model)
                .task {
                    #if DEBUG
                    if CommandLine.arguments.contains("-mockAlarm") {
                        recorder.seedDemoHistory(endingWith: .previewAlarm)
                        model.receive(.previewAlarm)
                        return
                    }
                    if CommandLine.arguments.contains("-mockReading") {
                        recorder.seedDemoHistory(endingWith: .preview)
                        model.receive(.preview)
                        return
                    }
                    #endif
                    await notifier.requestAuthorization()
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { widgetReloader.reloadNow() }
        }
    }
}
