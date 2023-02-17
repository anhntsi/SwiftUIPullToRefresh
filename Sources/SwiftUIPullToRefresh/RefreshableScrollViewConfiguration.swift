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
    let axis: Axis
    /// Header: Refresh control configuration
    let refreshControl: RefreshControlConfiguration
    /// Footer: Activity indicator configuration
    let activityIndicator: ActivityIndicatorConfiguration

    public static func normal() -> RefreshableScrollViewConfiguration {
        return RefreshableScrollViewConfiguration(
            axis: .vertical,
            refreshControl: RefreshControlConfiguration(),
            activityIndicator: ActivityIndicatorConfiguration()
        )
    }

    public init(axis: Axis, refreshControl: RefreshControlConfiguration, activityIndicator: ActivityIndicatorConfiguration) {
        self.axis = axis
        self.refreshControl = refreshControl
        self.activityIndicator = activityIndicator
    }
}

// MARK: RefreshControlConfiguration
public struct RefreshControlConfiguration {
    let tintColor: UIColor?
    let attributedTitle: NSAttributedString?

    public init(tintColor: UIColor? = nil, attributedTitle: NSAttributedString? = nil) {
        self.tintColor = tintColor
        self.attributedTitle = attributedTitle
    }
}

// MARK: ActivityIndicatorConfiguration
public struct ActivityIndicatorConfiguration {
    let style: UIActivityIndicatorView.Style
    let color: UIColor?
    let height: CGFloat

    public init(style: UIActivityIndicatorView.Style = .medium, color: UIColor? = nil, height: CGFloat = 0) {
        self.style = style
        self.color = color
        self.height = height
    }
}
