//
//  NSPathControlPointing.swift
//  South Lake
//
//  Created by Philip Dow on 3/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class NSPathControlWithCursor: NSPathControl {

    var cursor: NSCursor?

    override func resetCursorRects() {
        if let cursor = cursor {
            self.addCursorRect(self.bounds, cursor: cursor)
        } else {
            super.resetCursorRects()
        }
    }
}
