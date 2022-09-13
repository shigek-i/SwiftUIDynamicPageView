//
//  PageView.swift
//
//
//  Created by shigek-i on 2022/09/14.
//

import SwiftUI

public struct PageView<Selection: Hashable & Comparable, Content: View>: View {
    @Binding var selection: Selection

    let preparePreviousSelection: (Selection) -> Selection
    let prepareNextSelection: (Selection) -> Selection
    let onPageWillChange: ((Selection) -> Void)?
    let onPageChanged: ((Selection) -> Void)?

    let content: (Selection) -> Content

    public var body: some View {
        DynamicPageView(
            selection: $selection,
            preparePreviousSelection: preparePreviousSelection,
            prepareNextSelection: prepareNextSelection,
            content: content
        )
    }
}
