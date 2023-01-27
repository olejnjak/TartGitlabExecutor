import ArgumentParser
import Foundation
import System

public struct Run: AsyncParsableCommand {
    public init() {
        
    }
    
    public func run() async throws {
        let tart = TartService()
        let system = System.shared
        let vmID = ProcessInfo.processInfo.vmID
        let ip = try tart.ip(vmName: vmID)
        
        let isSuccess = system.ssh(
            host: ip,
            script: ProcessInfo.processInfo.arguments[1]
        )
        
        if !isSuccess {
            struct PipelineFailed: Error { }
            
            throw PipelineFailed()
        }
    }
}
