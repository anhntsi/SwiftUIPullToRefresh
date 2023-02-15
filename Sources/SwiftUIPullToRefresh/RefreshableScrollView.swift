//
//  RefreshableScrollView.swift
//  
//
//  Created by ANHNT on 15/02/2023.
//

import SwiftUI

#if os(iOS)

/// A `UIViewRepresentable` that wraps a `UIScrollView` and supports pull-to-refresh and infinite scrolling.
struct RefreshableScrollView<Content: View>: UIViewRepresentable {
    /// The scroll view's axis.
    let axis: Axis

    /// A binding to a boolean value that indicates whether the refresh control is currently refreshing.
    let isRefreshing: Binding<Bool>

    /// An optional closure to call when the user pulls down to refresh the content.
    let onRefresh: (() -> Void)?

    /// The view that contains the scrollable content.
    let content: Content

    /// Initializes a new instance of `RefreshableScrollView`.
    /// - Parameters:
    ///   - axis: The scroll view's axis. Defaults to `.vertical`.
    ///   - isRefreshing: A binding to a boolean value that indicates whether the refresh control is currently refreshing.
    ///   - onRefresh: An optional closure to call when the user pulls down to refresh the content.
    ///   - content: The view that contains the scrollable content.
    public init(_ axis: Axis = .vertical, isRefreshing: Binding<Bool>, onRefresh: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.axis = axis
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }

    /// Creates a `UIScrollView` with the specified properties and adds the content view to it.
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()

        // Create a UIHostingController to manage the content view and add it as a subview of the UIScrollView
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostingController.view)

        // Set constraints so the content view fills the scroll view
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        // Set properties of the UIScrollView based on the axis
        if axis == .vertical {
            scrollView.alwaysBounceVertical = true
        } else {
            scrollView.alwaysBounceHorizontal = true
        }

        // Add a UIRefreshControl to the UIScrollView if the onRefresh action is set
        if onRefresh != nil {
            let refreshControl = UIRefreshControl()
            refreshControl.tintColor = UIColor.white
            refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.refresh), for: .valueChanged)
            scrollView.refreshControl = refreshControl
        }

        // Return the UIScrollView
        return scrollView
    }

    /// Updates the scroll view when the `isRefreshing` binding changes.
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let refreshControl = uiView.refreshControl, isRefreshing.wrappedValue {
            refreshControl.beginRefreshing()
        } else if let refreshControl = uiView.refreshControl {
            refreshControl.endRefreshing()
        }
    }

    /// Creates a coordinator for the scroll view.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// A coordinator for the `RefreshableScrollView`.
    class Coordinator: NSObject {
        let parent: RefreshableScrollView

        init(_ parent: RefreshableScrollView) {
            self.parent = parent
        }

        /// Handles the user's pull-to-refresh action by calling the `onRefresh` closure.
        @objc func refresh() {
            parent.onRefresh?()
        }
    }
}
#endif
