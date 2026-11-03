import Foundation

public struct ReadingStore: Sendable {
    public static let appGroup = "group.ios.piron.marek.piotrowski.GazCoMonitor"
    public static let shared = ReadingStore()

    private let fileURL: URL?
    private static let fileName = "latestSensorReading.json"

    public init(appGroup: String = ReadingStore.appGroup) {
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        self.init(directory: directory)
    }

    public init(directory: URL?) {
        fileURL = directory?.appendingPathComponent(Self.fileName)
    }

    public func save(_ reading: SensorReading) {
        guard let fileURL, let data = try? JSONEncoder().encode(reading) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func load() -> SensorReading? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(SensorReading.self, from: data)
    }
}
