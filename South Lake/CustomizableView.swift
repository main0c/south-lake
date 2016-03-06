//
//  CustomizableView.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class CustomizableView: NSView {
    var backgroundColor: NSColor = NSColor(white: 1.0, alpha: 1.0)

    override func drawRect(dirtyRect: NSRect) {
        backgroundColor.setFill()
        NSRectFill(dirtyRect)
        super.drawRect(dirtyRect)
    }
    
}
