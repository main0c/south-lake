//
//  NSView+Identifier.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSView {

    // Similar to viewWithTag, finds views with the given identifier.

    func viewWithIdentifier(identifier: String) -> NSView? {
        for subview in self.subviews {
            if subview.identifier == identifier {
                return subview
            } else if subview.subviews.count > 0, let subview: NSView = subview.viewWithIdentifier(identifier) {
                return subview
            }
        }
        return nil
    }
}