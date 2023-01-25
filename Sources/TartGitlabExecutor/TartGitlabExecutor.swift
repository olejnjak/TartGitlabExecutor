import ArgumentParser
import ExecutorCore

@main
struct Main: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "tart-executor",
            subcommands: [
                Check.self,
                Clean.self,
                Prepare.self,
                Run.self,
            ]
        )
    }
}
