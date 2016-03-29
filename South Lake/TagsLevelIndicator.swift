//
//  TagsLevelIndicator.swift
//  South Lake
//
//  Created by Philip Dow on 3/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TagsLevelIndicator: NSView {

    dynamic var count: Int = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    let color = NSColor(red: 68.0/255.0, green: 163.0/255.0, blue: 64.0/255.0, alpha: 1.0) // 173
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        var y = floor(NSHeight(bounds)/2 - 10/2)
        var x = CGFloat(4.0)
        var row = 1
        
        let requiredWidth = CGFloat((count+1) * 14)
        let width = NSWidth(bounds)
        
        if requiredWidth > width {
            y += (10/2 + 2)
        }
        
        color.setFill()
        
        for _ in 0..<count {
            NSRectFill(NSMakeRect(x, y, 10, 10))
            x += (10+4)
            
            if (x+14) > width {
                x = CGFloat(4.0)
                y = floor(NSHeight(bounds)/2 - 10/2)
                y -= (10/2 + 2)
                
                row += 1
                if (row > 2) {
                    break
                }
            }
        }
    }
    
}
