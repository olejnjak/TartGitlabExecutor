import Foundation
import System

struct DiskMount {
    let path: String
    let isReadOnly: Bool = false
    
    var argumentString: String {
        [
            "--disk=",
            "\"",
            path,
            isReadOnly ? ":ro" : "",
            "\"",
        ].joined()
    }
}

struct DirMount {
    let name: String
    let path: String
    let isReadOnly: Bool = false
    
    var argumentString: String {
        [
            "--dir=",
            "\"",
            name,
            ":",
            path,
            isReadOnly ? ":ro" : "",
            "\"",
        ].joined()
    }
}

enum Networking {
    case bridged(String)
    case softnet
    
    var argumentString: String {
        switch self {
        case .bridged(let interface):
            return "--net-bridged " + interface
        case .softnet:
            return "--net-softnet"
        }
    }
}

struct TartService {
    let system: Systeming = System.shared
    
    func clone(
        sourceName: String,
        newName: String,
        insecure: Bool = false
    ) throws {
        try system.run([
            "tart",
            "clone",
            sourceName,
            newName,
            insecure ? "--insecure" : ""
        ].filter { $0.isEmpty })
    }
    
    func delete(
        vmName: String
    ) throws {
        try system.run([
            "tart",
            "delete",
            vmName
        ])
    }
    
    func ip(
        vmName: String,
        wait: TimeInterval = 0
    ) throws {
        try system.run([
            "tart",
            "ip",
            "--wait", String(Int(wait)),
            vmName
        ])
    }
    
    func prune(
        olderThan days: Int = 7,
        cacheBudget: Int?
    ) throws {
        try system.run([
            "tart",
            "prune",
            "--older-than", String(days),
            cacheBudget.map { "--cache-budget " + String($0) },
        ].compactMap { $0 })
    }
    
    func pull(
        vmName: String,
        insecure: Bool = false
    ) throws {
        try system.run([
            "tart",
            "pull",
            vmName,
            insecure ? "--insecure" : ""
        ].filter { $0.isEmpty })
    }
    
    func run(
        vmName: String,
        graphics: Bool = false,
        disk: [DiskMount] = [],
        dir: [DirMount] = [],
        network: Networking? = nil
    ) throws {
        try system.run([
            "tart",
            "run",
            vmName,
            graphics ? "--graphics" : "--no-graphics",
            disk.map(\.argumentString).joined(separator: " "),
            dir.map(\.argumentString).joined(separator: " "),
            network?.argumentString ?? ""
        ].filter { $0.isEmpty })
    }
    
    func stop(
        vmName: String,
        timeout: TimeInterval = 30
    ) throws {
        try system.run([
            "tart",
            "stop",
            "-t", String(Int(timeout)),
            vmName,
        ])
    }
}
