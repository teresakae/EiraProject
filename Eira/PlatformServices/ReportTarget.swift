import Foundation

enum ReportTarget: String, Sendable {
    case mock, real

    static var current: ReportTarget {
        #if DEBUG
        return .mock
        #else
        // Invalid or missing configuration fails closed.
        return ReportTarget(rawValue: Bundle.main.object(forInfoDictionaryKey: "EiraReportTarget") as? String ?? "") ?? .mock
        #endif
    }
}
