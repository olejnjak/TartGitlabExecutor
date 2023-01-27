import ArgumentParser
import Foundation
import System

public struct Setup: AsyncParsableCommand {
    public init() {
        
    }
    
    public func run() async throws {
        let label = "cz.olejnjak.TartGitlabExecutor"
        let plist = LaunchdPlist(
            label: label,
            programArguments: [
                ProcessInfo.processInfo.arguments.first ?? "",
                PrepareSSH._commandName,
            ],
            runAtLoad: true
        )
        let data = try PropertyListEncoder().encode(plist)
        let launchAgents = URL(filePath: NSString(
            string: "~/Library/LaunchAgents"
        ).expandingTildeInPath)
        
        try? FileManager.default.createDirectory(
            at: launchAgents,
            withIntermediateDirectories: true
        )
        
        try data.write(to: .init(
            filePath: launchAgents.appending(component: label + ".plist")
                .path(percentEncoded: false)
        ))
    }
}

private struct LaunchdPlist: Encodable {
    enum CodingKeys: String, CodingKey {
        case label = "Label"
        case programArguments = "ProgramArguments"
        case runAtLoad = "RunAtLoad"
    }
    
    let label: String
    let programArguments: [String]
    let runAtLoad: Bool
}
