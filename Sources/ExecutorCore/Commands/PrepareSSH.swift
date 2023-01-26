import ArgumentParser
import Foundation

public final class PrepareSSH: AsyncParsableCommand {
    public init() {
        
    }
    
    public func run() async throws {
        let locator = PublicKeyLocator()
        let urls = await locator.spotlightPublicKeys() + locator.predefinedPublicKeys()
        let destinationDir = URL(filePath: NSString("~/.ssh").expandingTildeInPath)
        let fm = FileManager.default
        
        try? fm.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        
        let authorizedKeys = destinationDir.appending(path: "authorized_keys")
        let allKeys = publicKeys(at: authorizedKeys) + urls.flatMap(publicKeys)
        
        try Set(allKeys).joined(separator: "\n")
            .write(to: authorizedKeys, atomically: true, encoding: .utf8)
    }
    
    private func publicKeys(at url: URL) -> [String] {
        let fm = FileManager.default
        let contentString = fm.contents(atPath: url.path(percentEncoded: false))
            .flatMap { String(data: $0, encoding: .utf8) }
        return contentString.map {
            $0.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        } ?? []
    }
}

private final class PublicKeyLocator {
    private var spotlightObservation: Any?
    private let baseLocation = URL(filePath: "/Volumes/My Shared Files")
    
    @MainActor
    func spotlightPublicKeys() async -> [URL] {
        let query = NSMetadataQuery()
        query.predicate = .init(format: "%K LIKE '*.pub'", argumentArray: [NSMetadataItemFSNameKey])
        query.valueListAttributes = [NSMetadataItemPathKey]
        query.searchScopes = [baseLocation]
        query.enableUpdates()
        
        await withUnsafeContinuation { continuation in
            spotlightObservation = NotificationCenter.default.addObserver(
                forName: .NSMetadataQueryDidFinishGathering,
                object: query,
                queue: nil
            ) { notification in
                continuation.resume()
            }
            
            guard query.start() else {
                continuation.resume()
                return
            }
        }
        
        query.stop()
        
        return query.results.compactMap { item -> URL? in
            guard let item = item as? NSMetadataItem else { return nil }
            return (item.value(forAttribute: NSMetadataItemPathKey) as? String).map { .init(filePath: $0) }
        }
    }
    
    func predefinedPublicKeys() -> [URL] {
        let location = baseLocation.appending(path: "ssh")
        let results = try? FileManager.default.contentsOfDirectory(
            at: location,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension.lowercased() == "pub" }
        
        return results ?? []
    }
}
