//
//  PageView.swift
//
//
//  Created by shigek-i on 2022/09/14.
//

import SwiftUI

public struct PageView<Selection: Hashable & Comparable, Content: View>: View {
    @Binding private var selection: Selection
    
    private let preparePreviousSelection: (Selection) -> Selection
    private let prepareNextSelection: (Selection) -> Selection
    private let onPageWillChange: ((Selection) -> Void)?
    private let onPageChanged: ((Selection) -> Void)?
    
    private let content: (Selection) -> Content
    
    public init(
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

    public var body: some View {
        DynamicPageView(
            selection: $selection,
            preparePreviousSelection: preparePreviousSelection,
            prepareNextSelection: prepareNextSelection,
            content: content
        )
    }
}
