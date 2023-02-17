//
//  RefreshableScrollViewConfiguration.swift
//  
//
//  Created by ANHNT on 17/02/2023.
//

import UIKit
import SwiftUI

// MARK: RefreshableScrollViewConfiguration
public struct RefreshableScrollViewConfiguration {
    /// The scroll view's axis.
    public let axis: Axis
    /// Header: Refresh control configuration
    public let refreshControl: RefreshControlConfiguration
    /// Footer: Activity indicator configuration
    public let activityIndicator: ActivityIndicatorConfiguration

    public static func normal() -> RefreshableScrollViewConfiguration {
        return RefreshableScrollViewConfiguration(
            axis: .vertical,
            refreshControl: RefreshControlConfiguration(),
            activityIndicator: ActivityIndicatorConfiguration()
        )
    }
}

// MARK: RefreshControlConfiguration
public struct RefreshControlConfiguration {
    public var tintColor: UIColor? = nil
    public var attributedTitle: NSAttributedString? = nil
}

// MARK: ActivityIndicatorConfiguration
public struct ActivityIndicatorConfiguration {
    public var style: UIActivityIndicatorView.Style = .medium
    public var color: UIColor? = nil
    public var height: CGFloat = 0
}
