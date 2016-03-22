//
//  TableRowView.swift
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TableRowView: NSTableRowView {

    override func drawSelectionInRect(dirtyRect: NSRect) {
        guard selectionHighlightStyle != .None else {
            return
        }
        
        NSColor(red: 238.0/255.0, green: 246.0/255.0, blue: 255.0/255.0, alpha: 1.0).setFill()
        NSRectFill(bounds)
    }
}
