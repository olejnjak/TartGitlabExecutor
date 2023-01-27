import ArgumentParser
import Foundation
import System

public struct Clean: AsyncParsableCommand {
    public init() {
        
    }
    
    public func run() async throws {
        let tart = TartService()
        let system = System.shared
        let vmID = ProcessInfo.processInfo.vmID
        
        try? tart.stop(vmName: vmID)
        try? tart.delete(vmName: vmID)
    }
}
