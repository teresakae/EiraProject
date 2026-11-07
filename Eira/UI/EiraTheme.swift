import SwiftUI

/// Shared colours and type from the Eira design reference.
enum EiraTheme {
    static let paper = Color(red: 0.965, green: 0.953, blue: 0.925)
    static let surface = Color(red: 0.988, green: 0.984, blue: 0.969)
    static let sage = Color(red: 0.247, green: 0.369, blue: 0.290)
    static let ink = Color(red: 0.149, green: 0.188, blue: 0.165)
    static let sageTint = Color(red: 0.894, green: 0.922, blue: 0.863)
    static let clay = Color(red: 0.604, green: 0.290, blue: 0.200)

    static let title = Font.custom("EiraFraunces-Bold", size: 24, relativeTo: .title2)
    static let story = Font.custom("EiraFraunces-Regular", size: 16, relativeTo: .body)
    static let body = Font.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline)
    static let micro = Font.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption)
    static let action = Font.custom("PlusJakartaSans-Regular", size: 18, relativeTo: .headline).weight(.medium)
}
