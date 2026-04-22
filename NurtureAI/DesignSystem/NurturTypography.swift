import SwiftUI

struct NurturTypography {
    // MARK: - Display
    static let largeTitle   = Font.custom("DMSans-Bold",     size: 34, relativeTo: .largeTitle)
    static let title        = Font.custom("DMSans-Bold",     size: 28, relativeTo: .title)
    static let title2       = Font.custom("DMSans-SemiBold", size: 22, relativeTo: .title2)
    static let title3       = Font.custom("DMSans-Medium",   size: 20, relativeTo: .title3)

    // MARK: - Body
    static let headline     = Font.custom("DMSans-SemiBold", size: 17, relativeTo: .headline)
    static let body         = Font.custom("DMSans-Regular",  size: 17, relativeTo: .body)
    static let callout      = Font.custom("DMSans-Regular",  size: 16, relativeTo: .callout)
    static let subheadline  = Font.custom("DMSans-Regular",  size: 15, relativeTo: .subheadline)

    // MARK: - Small
    static let footnote     = Font.custom("DMSans-Regular",  size: 13, relativeTo: .footnote)
    static let caption      = Font.custom("DMSans-Regular",  size: 12, relativeTo: .caption)
    static let caption2     = Font.custom("DMSans-Regular",  size: 11, relativeTo: .caption2)

    // MARK: - Emphasis variants
    static let bodyMedium   = Font.custom("DMSans-Medium",   size: 17, relativeTo: .body)
    static let captionMedium = Font.custom("DMSans-Medium",  size: 12, relativeTo: .caption)
}
