import SwiftUI
import WatchKit
import WidgetKit
import GasCoKit

@main
struct GasCoMonitorWatchApp: App {
    @State private var model: MonitorModel
    @Environment(\.scenePhase) private var scenePhase
    private let coordinator: SensorSourceCoordinator
    private let haptics = AlarmHaptics()
    private let reloader = WidgetReloader()

    // Set up in init so relayed readings are handled in background launches too.
    init() {
        let model = MonitorModel()
        _model = State(initialValue: model)
        coordinator = SensorSourceCoordinator(model: model)
        model.onNewReading = { [haptics, reloader] reading in
            haptics.handle(reading)
            reloader.handle(reading)
        }
        coordinator.start()
    }

    var body: some Scene {
        WindowGroup {
            MainView(model: model)
                .task {
                    #if DEBUG
                    if CommandLine.arguments.contains("-mockAlarm") { model.receive(.previewAlarm); return }
                    if CommandLine.arguments.contains("-mockReading") { model.receive(.preview); return }
                    #endif
                    if scenePhase == .active { coordinator.becameActive() }
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                coordinator.becameActive()
            case .background:
                coordinator.enteredBackground()
                BackgroundRefresh.schedule()
            default:
                break
            }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await BackgroundRefresh.run(model: model)
        }
        .backgroundTask(.watchConnectivity) {
            await coordinator.relay.waitForPendingContent()
        }
    }
}

enum BackgroundRefresh {
    static let identifier = "sensorRefresh"
    static let interval: TimeInterval = 15 * 60

    @MainActor
    static func schedule() {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: .now.addingTimeInterval(interval),
            userInfo: identifier as NSString
        ) { _ in }
    }

    @MainActor
    static func run(model: MonitorModel) async {
        // Readings relayed from the iPhone keep the complication current; use BLE only when they stopped.
        if let reading = model.reading, !reading.isStale(after: interval) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.sensor)
            schedule()
            return
        }
        _ = await model.refreshOnce(timeout: .seconds(20))
        // Release the sensor's single connection for the iPhone.
        model.stop()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.sensor)
        schedule()
    }
}
