import Foundation
import Testing
@testable import GasCoKit

struct SensorFrameParserTests {
    @Test func parsesValues() throws {
        let reading = try #require(SensorFrameParser.parse(Data([42, 7, 1, 1])))
        #expect(reading.co == 42)
        #expect(reading.gas == 7)
    }

    @Test func alarmByteZeroMeansAlarm() throws {
        let reading = try #require(SensorFrameParser.parse(Data([10, 10, 0, 1])))
        #expect(reading.isCOAlarmActive)
        #expect(!reading.isGasAlarmActive)
    }

    @Test func missingAlarmBytesMeanNoAlarm() throws {
        let reading = try #require(SensorFrameParser.parse(Data([10, 10])))
        #expect(!reading.isAnyAlarmActive)
    }

    @Test func tooShortFrameIsRejected() {
        #expect(SensorFrameParser.parse(Data([1])) == nil)
    }
}

struct DangerLevelTests {
    @Test(arguments: [(0, DangerLevel.safe), (50, .safe), (51, .warning), (70, .warning), (71, .danger), (255, .danger)])
    func thresholds(value: Int, expected: DangerLevel) {
        #expect(DangerLevel(value: value) == expected)
    }

    @Test func alarmForcesDanger() {
        #expect(DangerLevel(value: 0, isAlarmActive: true) == .danger)
    }

    @Test func staleness() {
        let old = SensorReading(co: 0, gas: 0, isCOAlarmActive: false, isGasAlarmActive: false,
                                timestamp: .now.addingTimeInterval(-16 * 60))
        #expect(old.isStale())
        #expect(!SensorReading.preview.isStale())
    }
}

struct ReadingStoreTests {
    @Test func roundTrip() {
        let store = ReadingStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        store.save(.previewAlarm)
        #expect(store.load()?.co == SensorReading.previewAlarm.co)
    }
}

struct RelayPayloadTests {
    @Test func roundTrip() throws {
        let decoded = try #require(RelayPayload.decode(RelayPayload.encode(.previewAlarm)))
        #expect(decoded == SensorReading.previewAlarm)
    }

    @Test func invalidPayloadIsRejected() {
        #expect(RelayPayload.decode([:]) == nil)
        #expect(RelayPayload.decode(["reading": Data([1, 2, 3])]) == nil)
    }
}

@MainActor
struct MonitorModelRelayTests {
    private func makeModel() -> MonitorModel {
        MonitorModel(store: ReadingStore(directory: nil))
    }

    @Test func relayedReadingUpdatesModel() {
        let model = makeModel()
        let reading = SensorReading(co: 5, gas: 6, isCOAlarmActive: false, isGasAlarmActive: false)
        model.receiveRelayed(reading)
        #expect(model.reading == reading)
        #expect(model.isRelayFresh())
    }

    @Test func olderRelayedReadingIsIgnored() {
        let model = makeModel()
        let newer = SensorReading(co: 5, gas: 6, isCOAlarmActive: false, isGasAlarmActive: false)
        let older = SensorReading(co: 9, gas: 9, isCOAlarmActive: false, isGasAlarmActive: false,
                                  timestamp: newer.timestamp.addingTimeInterval(-10))
        model.receiveRelayed(newer)
        model.receiveRelayed(older)
        #expect(model.reading == newer)
    }

    @Test func relayGoesStale() {
        let model = makeModel()
        model.receiveRelayed(SensorReading(co: 1, gas: 1, isCOAlarmActive: false, isGasAlarmActive: false,
                                           timestamp: .now.addingTimeInterval(-MonitorModel.relayFreshness - 1)))
        #expect(!model.isRelayFresh())
    }
}
