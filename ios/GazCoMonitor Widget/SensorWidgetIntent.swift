import AppIntents
import WidgetKit

enum SensorSelection: String, AppEnum {
    case both
    case co
    case gas

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Czujnik"
    static let caseDisplayRepresentations: [SensorSelection: DisplayRepresentation] = [
        .both: "CO i Gaz",
        .co: "CO",
        .gas: "Gaz"
    ]
}

struct SensorWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Czujnik Gaz / CO"
    static let description = IntentDescription("Wybierz, który odczyt pokazać.")

    @Parameter(title: "Czujnik", default: .both)
    var sensor: SensorSelection

    init() {}

    init(sensor: SensorSelection) {
        self.sensor = sensor
    }
}
