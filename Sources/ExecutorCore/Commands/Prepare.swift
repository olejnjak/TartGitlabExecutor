import ArgumentParser
import Foundation
import System

public struct Prepare: AsyncParsableCommand {
    public init() {
        
    }
    
    public func run() async throws {
        struct NoImage: Error { }
        struct CannotStart: Error { }
        
        guard let image = ProcessInfo.processInfo.vmImage else {
            throw NoImage()
        }
        
        let tart = TartService()
        let system = System.shared
        let vmID = ProcessInfo.processInfo.vmID
        
        try tart.clone(sourceName: image, newName: vmID)
        try tart.run(
            vmName: vmID,
            dir: [
                .init(name: "ssh", path: "~/.ssh")
            ],
            network: .softnet
        )
        
        let ip = try tart.ip(vmName: "pipeline")
        
        for i in 0..<30 {
            try await Task.sleep(for: .seconds(1))
            
            if system.ssh(ip: ip) {
                break
            }
            
            if i == 30 {
                throw CannotStart()
            }
        }
    }
}
