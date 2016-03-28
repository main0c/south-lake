//
//  TableRowView.swift
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TableRowView: NSTableRowView {

    static let keyColor = UI.Color.Selection.KeyView
    static let keylessColor = UI.Color.Selection.NotKeyView

    override func drawSelectionInRect(dirtyRect: NSRect) {
        guard selectionHighlightStyle != .None else {
            return
        }
        guard let window = window else {
            return
        }
        
        let inChain = inResponderChain
        
        if window.keyWindow && inChain {
            TableRowView.keyColor.setFill()
        } else {
            TableRowView.keylessColor.setFill()
        }
        
        NSRectFill(bounds)
    }
}
