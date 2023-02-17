//
//  RefreshableScrollView.swift
//  
//
//  Created by ANHNT on 15/02/2023.
//

import SwiftUI

#if os(iOS)

/// A `UIViewRepresentable` that wraps a `UIScrollView` and supports pull-to-refresh and infinite scrolling.
public struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    /// Configuration of scroll view: axis, refresh control, activity indicator.
    let configuration: RefreshableScrollViewConfiguration

    /// A binding to a boolean value that indicates whether the refresh control is currently refreshing.
    let isRefreshing: Binding<Bool>

    /// An optional closure to call when the user pulls down to refresh the content.
    let onRefresh: (() -> Void)?

    /// A binding to a boolean value that indicates whether the scroll view is currently loading more content.
    var isLoadingMore: Binding<Bool>

    /// An optional closure to call when the scroll view reaches the bottom and needs to load more content.
    let onLoadMore: (() -> Void)?

    /// The view that contains the scrollable content.
    let content: Content

    /// Initializes a new instance of `RefreshableScrollView`.
    /// - Parameters:
    ///   - configuration: Configuration of scroll view: axis, refresh control, activity indicator.
    ///   - isRefreshing: A binding to a boolean value that indicates whether the refresh control is currently refreshing.
    ///   - onRefresh: An optional closure to call when the user pulls down to refresh the content.
    ///   - isLoadingMore: A binding to a boolean value that indicates whether the scroll view is currently loading more content.
    ///   - onLoadMore: An optional closure to call when the scroll view reaches the bottom and needs to load more content.
    ///   - content: The view that contains the scrollable content.
    public init(
        _ configuration: RefreshableScrollViewConfiguration = RefreshableScrollViewConfiguration.normal(),
        isRefreshing: Binding<Bool> = .constant(false),
        onRefresh: (() -> Void)? = nil,
        isLoadingMore: Binding<Bool> = .constant(false),
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
        self.content = content()
    }

    /// Creates a `UIScrollView` with the specified properties and adds the content view to it.
    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()

        context.coordinator.addContentView(to: scrollView, content: content)

        // Set properties of the UIScrollView based on the axis
        if configuration.axis == .vertical {
            scrollView.alwaysBounceVertical = true
        } else {
            scrollView.alwaysBounceHorizontal = true
        }

        // Add a UIRefreshControl to the UIScrollView if the onRefresh action is set
        if onRefresh != nil {
            context.coordinator.addRefreshControl(to: scrollView)
        }

        if onLoadMore != nil {
            scrollView.delegate = context.coordinator
            context.coordinator.addActivityIndicator(to: scrollView)
        }

        // Return the UIScrollView
        return scrollView
    }

    /// Updates the scroll view when the `isRefreshing` or `isLoadingMore` binding changes.
    public func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.updateContentView(to: uiView, content: content)
        context.coordinator.updateRefreshControl(isRefreshing: isRefreshing.wrappedValue, isLoadingMore: isLoadingMore.wrappedValue)
        context.coordinator.updateActivityIndicator(to: uiView, isRefreshing: isRefreshing.wrappedValue, isLoadingMore: isLoadingMore.wrappedValue)
    }

    /// Creates a coordinator for the scroll view.
    public func makeCoordinator() -> Coordinator<Content> {
        Coordinator(self)
    }

    // MARK: - Coordinator
    /// A coordinator for the `RefreshableScrollView`.
    public class Coordinator<Content: View>: NSObject, UIScrollViewDelegate {
        /// The parent `RefreshableScrollView`.
        let parent: RefreshableScrollView

        /// The UIHostingController that manages the content view.
        var hostingController: UIHostingController<Content>?

        /// A Boolean value that indicates whether the refresh control is currently refreshing the scroll view.
        var isRefreshing: Bool = false

        /// The UIRefreshControl used to refresh the scroll view.
        var refreshControl: UIRefreshControl?

        /// A Boolean value that indicates whether the activity indicator is currently loading more data.
        var isLoadingMore: Bool = false

        /// The UIActivityIndicatorView used to show that more data is being loaded.
        var activityIndicator: UIActivityIndicatorView?

        init(_ parent: RefreshableScrollView) {
            self.parent = parent
        }

        /// Handles the user's pull-to-refresh action by calling the `onRefresh` closure.
        @objc func onPullToRefresh() {
            if isLoadingMore {
                refreshControl?.endRefreshing()
                return
            }
            parent.onRefresh?()
        }

        // MARK: - Body: Content View

        /// Adds the content view as a subview of the scroll view and sets its constraints.
        ///
        /// - Parameters:
        ///   - scrollView: The scroll view that the content view will be added to.
        ///   - content: The content view to add to the scroll view.
        func addContentView(to scrollView: UIScrollView, content: Content) {
            // Create a UIHostingController to manage the content view and add it as a subview of the UIScrollView
            let hostingController = UIHostingController(rootView: content)
            scrollView.addSubview(hostingController.view)

            // Set constraints so the content view fills the scroll view
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.rootView = content
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
            ])

            self.hostingController = hostingController
        }

        /// Updates the content view by replacing it with a new content view.
        ///
        /// - Parameter content: The new content view to replace the existing one with.
        func updateContentView(to scrollView: UIScrollView, content: Content) {
            hostingController?.rootView = content
            hostingController?.view.invalidateIntrinsicContentSize()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
                let contentSize = self?.hostingController?.view.frame.size ?? .zero
                var contentOffset = scrollView.contentOffset
                if contentOffset.y > contentSize.height {
                    contentOffset.y = contentSize.height - scrollView.frame.size.height
                    scrollView.setContentOffset(contentOffset, animated: false)
                }
            })
        }

        // MARK: - Header: Refresh Control

        /// Creates and configures a `UIRefreshControl` for the scroll view.
        ///
        /// - Returns: A new `UIRefreshControl` instance.
        private func makeRefreshControl() -> UIRefreshControl {
            let refreshControl = UIRefreshControl()
            if let tintColor = parent.configuration.refreshControl.tintColor {
                refreshControl.tintColor = tintColor
            }
            if let attributedTitle = parent.configuration.refreshControl.attributedTitle {
                refreshControl.attributedTitle = attributedTitle
            }
            refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            self.refreshControl = refreshControl
            return refreshControl
        }

        /// Creates and configures a `UIActivityIndicatorView` to show that more data is being loaded.
        ///
        /// - Returns: A new `UIActivityIndicatorView` instance.
        private func makeActivityIndicator() -> UIActivityIndicatorView {
            let activityIndicator = UIActivityIndicatorView(style: parent.configuration.activityIndicator.style)
            if let tintColor = parent.configuration.activityIndicator.color {
                activityIndicator.color = tintColor
            }
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.hidesWhenStopped = true
            self.activityIndicator = activityIndicator
            return activityIndicator
        }

        /// Adds the refresh control to the scroll view.
        ///
        /// - Parameter scrollView: The scroll view to add the refresh control to.
        func addRefreshControl(to scrollView: UIScrollView) {
            let refreshControl = makeRefreshControl()
            scrollView.refreshControl = refreshControl
        }

        /// Updates the refresh control based on the given state.
        ///
        /// - Parameters:
        ///   - isRefreshing: A boolean indicating whether the refresh control is refreshing.
        ///   - isLoadingMore: A boolean indicating whether the refresh control is loading more content.
        func updateRefreshControl(isRefreshing: Bool, isLoadingMore: Bool) {
            self.isRefreshing = isRefreshing
            guard !isLoadingMore else {
                return
            }
            if isRefreshing {
                refreshControl?.beginRefreshing()
            } else {
                refreshControl?.endRefreshing()
            }
        }

        // MARK: - Footer: Activity Indicator

        /// Adds an activity indicator to the footer of the given scroll view.
        /// - Parameter scrollView: The scroll view to which the activity indicator will be added.
        func addActivityIndicator(to scrollView: UIScrollView) {
            let activityIndicator = makeActivityIndicator()
            scrollView.addSubview(activityIndicator)
            let activityIndicatorHeight = activityIndicator.bounds.height + 8
            let configurationHeight = parent.configuration.activityIndicator.height
            let height = configurationHeight > activityIndicatorHeight ? configurationHeight : activityIndicatorHeight
            let padding = (height - activityIndicator.bounds.height) / 2
            let bottomPadding = activityIndicator.bounds.height + padding
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
                activityIndicator.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: bottomPadding)
            ])

            // Add a content inset to the bottom of the scroll view to show the activity indicator
            let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
            scrollView.contentInset = contentInset
            scrollView.scrollIndicatorInsets = contentInset
        }

        /// Updates the activity indicator based on the given state.
        ///
        /// - Parameters:
        ///   - scrollView: The scroll view containing the activity indicator.
        ///   - isRefreshing: A boolean indicating whether the refresh control is refreshing.
        ///   - isLoadingMore: A boolean indicating whether the refresh control is loading more content.
        func updateActivityIndicator(to scrollView: UIScrollView, isRefreshing: Bool, isLoadingMore: Bool) {
            self.isLoadingMore = isLoadingMore
            guard !isRefreshing else {
                return
            }
            if isLoadingMore {
                activityIndicator?.startAnimating()
            } else {
                activityIndicator?.stopAnimating()
            }
        }

        /// Removes the activity indicator from its superview.
        func removeActivityIndicator() {
            activityIndicator?.removeFromSuperview()
        }

        // MARK: - UIScrollViewDelegate
        public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            guard !isRefreshing || !isLoadingMore else {
                return
            }

            if isNearBottomEdge(scrollView: scrollView) {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(makeOnLoadMore), object: nil)
                perform(#selector(makeOnLoadMore), with: nil, afterDelay: 0.3)
            }
        }

        @objc private func makeOnLoadMore() {
            parent.onLoadMore?()
        }

        private func isNearBottomEdge(scrollView: UIScrollView, edgeOffset: CGFloat = 20.0) -> Bool {
            scrollView.contentOffset.y + scrollView.frame.size.height + edgeOffset > scrollView.contentSize.height
        }
    }
}

#endif
