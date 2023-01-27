import ArgumentParser
import Foundation
import System

public struct Prepare: AsyncParsableCommand {
    public init() {
        
    }
    
    public func run() async throws {
        struct CannotStart: Error { }
        
        guard let image = ProcessInfo.processInfo.vmImage else {
            Foundation.exit(2)
            throw NoImageError()
        }
        
        let tart = TartService()
        let system = System.shared
        let vmID = ProcessInfo.processInfo.vmID
        
        do {
            try tart.clone(sourceName: image, newName: vmID)
        } catch {
            Foundation.exit(3)
        }
        do {
            try tart.run(
                vmName: vmID,
                dir: [
                    .init(name: "ssh", path: "~/.ssh")
                ],
                network: .softnet
            )
        } catch {
            Foundation.exit(4)
        }
        
        do {
            let ip = try tart.ip(
                vmName: vmID,
                wait: 10
            )
            
            for i in 0..<30 {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    Foundation.exit(5)
                }
                
                if system.ssh(host: ip) {
                    break
                }
                
                if i == 30 {
                    Foundation.exit(6)
                    throw CannotStart()
                }
            }
        } catch {
            Foundation.exit(7)
        }
    }
}
