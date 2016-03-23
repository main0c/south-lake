//
//  TableRowView.swift
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TableRowView: NSTableRowView {

    static let keyColor = NSColor(red: 238.0/255.0, green: 246.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    static let keylessColor = NSColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1.0)

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
