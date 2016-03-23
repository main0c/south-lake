//
//  NSView+ResponderChain.swift
//  South Lake
//
//  Created by Philip Dow on 3/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSView {
    var inResponderChain: Bool {
        guard let window = window else {
            return false
        }
        
        var inChain = false
        var view: NSView? = self
        while view != nil {
            if window.firstResponder == view {
                inChain = true
                break
            }
            view = view!.superview
        }
        
        return inChain
    }
}