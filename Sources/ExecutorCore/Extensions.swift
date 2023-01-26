import Foundation

extension ProcessInfo {
    var vmID: String {
        let runnerID = environment["CUSTOM_ENV_CI_RUNNER_ID"]
        let projectID = environment["CUSTOM_ENV_CI_PROJECT_ID"]
        let concurrentID = environment["CUSTOM_ENV_CI_CONCURRENT_PROJECT_ID"]
        let jobID = environment["CUSTOM_ENV_CI_JOB_ID"]
        
        return [
            "runner",
            projectID,
            "concurrent",
            concurrentID,
            "job",
            jobID,
        ].compactMap { $0 }.joined(separator: "-")
    }
    
    var vmImage: String? { environment["CUSTOM_ENV_CI_JOB_IMAGE"] }
}
