import Combine
import CombineExt
import Foundation
import TSCBasic

struct SystemError: Error {
    let command: String
    let code: Int32
    let standardError: Data
}

extension ProcessResult {
    /// Throws a SystemError if the result is unsuccessful.
    ///
    /// - Throws: A SystemError.
    func throwIfErrored() throws {
        switch exitStatus {
        case let .signalled(code):
            let data = Data(try stderrOutput.get())
            throw SystemError(command: command(), code: code, standardError: data)
        case let .terminated(code):
            if code != 0 {
                let data = Data(try stderrOutput.get())
                throw SystemError(command: command(), code: code, standardError: data)
            }
        }
    }
    
    /// It returns the command that the process executed.
    /// If the command is executed through xcrun, then the name of the tool is returned instead.
    /// - Returns: Returns the command that the process executed.
    func command() -> String {
        let command = arguments.first!
        if command == "/usr/bin/xcrun" {
            return arguments[1]
        }
        return command
    }
}

// swiftlint:disable:next type_body_length
public final class System: Systeming {    
    /// Shared system instance.
    public static var shared: Systeming = System()

    /// Regex expression used to get the Swift version (for example, 5.7) from the output of the 'swift --version' command.
    // swiftlint:disable:next force_try
    private static var swiftVersionRegex = try! NSRegularExpression(pattern: "Apple Swift version\\s(.+)\\s\\(.+\\)", options: [])

    /// Regex expression used to get the Swiftlang version (for example, 5.7.0.127.4) from the output of the 'swift --version' command.
    // swiftlint:disable:next force_try
    private static var swiftlangVersion = try! NSRegularExpression(pattern: "swiftlang-(.+)\\sclang", options: [])

    /// Convenience shortcut to the environment.
    public var env: [String: String] {
        ProcessInfo.processInfo.environment
    }

    func escaped(arguments: [String]) -> String {
        arguments.map { $0.spm_shellEscaped() }.joined(separator: " ")
    }

    // MARK: - Init

    // MARK: - Systeming

    public func run(_ arguments: [String]) throws {
        _ = try capture(arguments)
    }
    
    public func runOnBackground(_ arguments: [String]) throws {
        let process = Process(
            arguments: arguments,
            outputRedirection: .collect,
            startNewProcessGroup: false
        )

        os_log(.debug, "%@", escaped(arguments: arguments))

        try process.launch()
    }

    public func capture(_ arguments: [String]) throws -> String {
        try capture(arguments, verbose: false, environment: env)
    }

    public func capture(
        _ arguments: [String],
        verbose: Bool,
        environment: [String: String]
    ) throws -> String {
        let process = Process(
            arguments: arguments,
            environment: environment,
            outputRedirection: .collect,
            startNewProcessGroup: false,
            loggingHandler: verbose ? { message in
                stdoutStream <<< message <<< "\n"
                stdoutStream.flush()
            } : nil
        )

        os_log(.debug, "%@", escaped(arguments: arguments))

        try process.launch()
        let result = try process.waitUntilExit()
        let output = try result.utf8Output()

        os_log(.debug, "%@", output)

        try result.throwIfErrored()

        return try result.utf8Output()
    }

    public func runAndPrint(_ arguments: [String]) throws {
        try runAndPrint(arguments, verbose: false, environment: env)
    }

    public func runAndPrint(
        _ arguments: [String],
        verbose: Bool,
        environment: [String: String]
    ) throws {
        try runAndPrint(
            arguments,
            verbose: verbose,
            environment: environment,
            redirection: .none
        )
    }

    public func runAndCollectOutput(_ arguments: [String]) async throws -> SystemCollectedOutput {
        var values = publisher(arguments)
            .mapToString()
            .collectOutput().values.makeAsyncIterator()

        return try await values.next()!
    }

    public func async(_ arguments: [String]) throws {
        let process = Process(
            arguments: arguments,
            environment: env,
            outputRedirection: .none,
            startNewProcessGroup: true
        )

        os_log(.debug, "%@", escaped(arguments: arguments))

        try process.launch()
    }

    public func which(_ name: String) throws -> String {
        try capture(["/usr/bin/env", "which", name]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Helpers

    /// Converts an array of arguments into a `Foundation.Process`
    /// - Parameters:
    ///   - arguments: Arguments for the process, first item being the executable URL.
    ///   - environment: Environment
    /// - Returns: A `Foundation.Process`
    static func process(
        _ arguments: [String],
        environment: [String: String]
    ) -> Foundation.Process {
        let executablePath = arguments.first!
        let process = Foundation.Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = Array(arguments.dropFirst())
        process.environment = environment
        return process
    }

    /// Pipe the output of one Process to another
    /// - Parameters:
    ///   - processOne: First Process
    ///   - processTwo: Second Process
    /// - Returns: The pipe
    @discardableResult
    static func pipe(
        _ processOne: inout Foundation.Process,
        _ processTwo: inout Foundation.Process
    ) -> Pipe {
        let processPipe = Pipe()

        processOne.standardOutput = processPipe
        processTwo.standardInput = processPipe
        return processPipe
    }

    /// PIpe the output of a process into separate output and error pipes
    /// - Parameter process: The process to pipe
    /// - Returns: Tuple that contains the output and error Pipe.
    static func pipeOutput(_ process: inout Foundation.Process) -> (stdOut: Pipe, stdErr: Pipe) {
        let stdOut = Pipe()
        let stdErr = Pipe()

        // Redirect output of Process Two
        process.standardOutput = stdOut
        process.standardError = stdErr

        return (stdOut, stdErr)
    }

    public func chmod(
        _ mode: FileMode,
        path: AbsolutePath,
        options: Set<FileMode.Option>
    ) throws {
        try localFileSystem.chmod(mode, path: path, options: options)
    }

    private func runAndPrint(
        _ arguments: [String],
        verbose: Bool,
        environment: [String: String],
        redirection: TSCBasic.Process.OutputRedirection
    ) throws {
        let process = Process(
            arguments: arguments,
            environment: environment,
            outputRedirection: .stream(stdout: { bytes in
                FileHandle.standardOutput.write(Data(bytes))
                redirection.outputClosures?.stdoutClosure(bytes)
            }, stderr: { bytes in
                FileHandle.standardError.write(Data(bytes))
                redirection.outputClosures?.stderrClosure(bytes)
            }),
            startNewProcessGroup: false,
            loggingHandler: verbose ? { message in
                stdoutStream <<< message <<< "\n"
                stdoutStream.flush()
            } : nil
        )

        os_log(.debug, "%@", escaped(arguments: arguments))

        try process.launch()
        let result = try process.waitUntilExit()
        let output = try result.utf8Output()

        os_log(.debug, "%@", output)

        try result.throwIfErrored()
    }

    // swiftlint:disable:next function_body_length
    private func publisher(
        _ arguments: [String],
        environment: [String: String],
        pipeTo secondArguments: [String]
    ) -> AnyPublisher<SystemEvent<Data>, Error> {
        .create { subscriber in
            let synchronizationQueue = DispatchQueue(label: "io.tuist.support.system")
            var errorData: [UInt8] = []
            var processOne = System.process(arguments, environment: environment)
            var processTwo = System.process(secondArguments, environment: environment)

            System.pipe(&processOne, &processTwo)

            let pipes = System.pipeOutput(&processTwo)

            pipes.stdOut.fileHandleForReading.readabilityHandler = { fileHandle in
                synchronizationQueue.async {
                    let data: Data = fileHandle.availableData
                    if !data.isEmpty {
                        subscriber.send(.standardOutput(Data(data)))
                    }
                }
            }

            pipes.stdErr.fileHandleForReading.readabilityHandler = { fileHandle in
                synchronizationQueue.async {
                    let data: Data = fileHandle.availableData
                    errorData.append(contentsOf: data)
                    if !data.isEmpty {
                        subscriber.send(.standardError(Data(data)))
                    }
                }
            }

            DispatchQueue.global().async {
                do {
                    try processOne.run()
                    try processTwo.run()
                    processOne.waitUntilExit()

                    let exitStatus = ProcessResult.ExitStatus.terminated(code: processOne.terminationStatus)
                    let result = ProcessResult(
                        arguments: arguments,
                        environment: environment,
                        exitStatus: exitStatus,
                        output: .success([]),
                        stderrOutput: .success(errorData)
                    )
                    try result.throwIfErrored()
                    synchronizationQueue.sync {
                        subscriber.send(completion: .finished)
                    }
                } catch {
                    synchronizationQueue.sync {
                        subscriber.send(completion: .failure(error))
                    }
                }
            }
            return AnyCancellable {
                pipes.stdOut.fileHandleForReading.readabilityHandler = nil
                pipes.stdErr.fileHandleForReading.readabilityHandler = nil
                if processOne.isRunning {
                    processOne.terminate()
                }
            }
        }
    }
    
    public func publisher(
            _ arguments: [String],
            verbose: Bool,
            environment: [String: String]
        ) -> AnyPublisher<SystemEvent<Data>, Error> {
            .create { subscriber in
                let synchronizationQueue = DispatchQueue(label: "io.tuist.support.system")
                var errorData: [UInt8] = []
                let process = Process(
                    arguments: arguments,
                    environment: environment,
                    outputRedirection: .stream(stdout: { bytes in
                        synchronizationQueue.async {
                            subscriber.send(.standardOutput(Data(bytes)))
                        }
                    }, stderr: { bytes in
                        synchronizationQueue.async {
                            errorData.append(contentsOf: bytes)
                            subscriber.send(.standardError(Data(bytes)))
                        }
                    }),
                    startNewProcessGroup: false,
                    loggingHandler: verbose ? { message in
                        stdoutStream <<< message <<< "\n"
                        stdoutStream.flush()
                    } : nil
                )
                DispatchQueue.global().async {
                    do {
                        try process.launch()
                        var result = try process.waitUntilExit()
                        result = ProcessResult(
                            arguments: result.arguments,
                            environment: environment,
                            exitStatus: result.exitStatus,
                            output: result.output,
                            stderrOutput: result.stderrOutput.map { _ in errorData }
                        )
                        try result.throwIfErrored()
                        synchronizationQueue.sync {
                            subscriber.send(completion: .finished)
                        }
                    } catch {
                        synchronizationQueue.sync {
                            subscriber.send(completion: .failure(error))
                        }
                    }
                }
                return AnyCancellable {
                    if process.launched {
                        process.signal(9) // SIGKILL
                    }
                }
            }
        }

    public func publisher(_ arguments: [String]) -> AnyPublisher<SystemEvent<Data>, Error> {
        publisher(arguments, verbose: false, environment: env)
    }

    public func publisher(_ arguments: [String], pipeTo secondArguments: [String]) -> AnyPublisher<SystemEvent<Data>, Error> {
        publisher(arguments, environment: env, pipeTo: secondArguments)
    }
}
