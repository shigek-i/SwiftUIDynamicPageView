//
//  DynamicPageView.swift
//  
//
//  Created by shigek-i on 2022/09/14.
//

import SwiftUI

internal struct DynamicPageView<Selection: Hashable & Comparable, Content: View>: UIViewControllerRepresentable {
    @Binding private var selection: Selection
    
    private let preparePreviousSelection: (Selection) -> Selection
    private let prepareNextSelection: (Selection) -> Selection
    private let onPageWillChange: ((Selection) -> Void)?
    private let onPageChanged: ((Selection) -> Void)?
    
    private let content: (Selection) -> Content
    
    init(
        selection: Binding<Selection>,
        preparePreviousSelection: @escaping (Selection) -> Selection,
        prepareNextSelection: @escaping (Selection) -> Selection,
        onPageWillChange: ((Selection) -> Void)? = nil,
        onPageChanged: ((Selection) -> Void)? = nil,
        @ViewBuilder content: @escaping (Selection) -> Content
    ) {
        self._selection = selection
        self.preparePreviousSelection = preparePreviousSelection
        self.prepareNextSelection = prepareNextSelection
        self.onPageChanged = onPageChanged
        self.onPageWillChange = onPageWillChange
        self.content = content
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, pageViewController: UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal))
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = context.coordinator.pageViewController
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        return pageViewController
    }
    
    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        if let controller = context.coordinator.pageViewController.viewControllers?.first as? TaggedUIHostingController {
            controller.rootView = content(controller.tag)
            if controller.tag != selection {
                context.coordinator.pageTo(selection, direction: controller.tag < selection ? .forward : .reverse)
            }
        }
    }
}

// MARK: TaggedUIHostingController
extension DynamicPageView {
    private class TaggedUIHostingController: UIHostingController<Content> {
        let tag: Selection
        
        init(rootView: Content, tag: Selection) {
            self.tag = tag
            super.init(rootView: rootView)
        }
        
        @MainActor required dynamic init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension DynamicPageView {
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        private let parent: DynamicPageView
        let pageViewController: UIPageViewController
        
        init(_ parent: DynamicPageView, pageViewController: UIPageViewController) {
            self.parent = parent
            self.pageViewController = pageViewController
            
            let controller = TaggedUIHostingController(rootView: parent.content(parent.selection), tag: parent.selection)
            pageViewController.setViewControllers([controller], direction: .forward, animated: true)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let tag = (viewController as? TaggedUIHostingController)?.tag else {
                return nil
            }
            let previousSelection = parent.preparePreviousSelection(tag)
            return TaggedUIHostingController(rootView: parent.content(previousSelection), tag: previousSelection)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let tag = (viewController as? TaggedUIHostingController)?.tag else {
                return nil
            }
            let nextSelection = parent.prepareNextSelection(tag)
            return TaggedUIHostingController(rootView: parent.content(nextSelection), tag: nextSelection)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed,
                  let controller = pageViewController.viewControllers?.first as? TaggedUIHostingController else {
                return
            }
            self.parent.selection = controller.tag
            self.parent.onPageChanged?(controller.tag)
            controller.rootView = self.parent.content(controller.tag)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
            guard let controller = pendingViewControllers.first as? TaggedUIHostingController else {
                return
            }
            self.parent.onPageWillChange?(controller.tag)
            controller.rootView = self.parent.content(controller.tag)
        }
        
        func pageTo(_ selection: Selection, direction: UIPageViewController.NavigationDirection) {
            DispatchQueue.main.async {
                self.pageViewController.setViewControllers(
                    [TaggedUIHostingController(rootView: self.parent.content(selection), tag: selection)],
                    direction: direction,
                    animated: true
                ) { _ in
                    DispatchQueue.main.async {
                        self.pageViewController.setViewControllers(
                            [TaggedUIHostingController(rootView: self.parent.content(selection), tag: selection)],
                            direction: direction,
                            animated: false
                        ) { _ in
                            guard let controller = (self.pageViewController.viewControllers?.first as? TaggedUIHostingController) else {
                                return
                            }
                            controller.rootView = self.parent.content(controller.tag)
                        }
                    }
                }
            }
        }
    }
}
