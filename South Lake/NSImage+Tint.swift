//
//  NSImage+Tint.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSImage {
    
    func tintedImage(color: NSColor) -> NSImage {

        let tinted = copy() as! NSImage
        tinted.lockFocus()
        color.set()

        let imageRect = NSRect(origin: NSZeroPoint, size: size)
        NSRectFillUsingOperation(imageRect, .CompositeSourceAtop)

        tinted.unlockFocus()
        return tinted
    }

}