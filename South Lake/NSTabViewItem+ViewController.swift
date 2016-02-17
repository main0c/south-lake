//
//  NSTabViewItem+ViewController.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Adds a vc (viewController) property to NSTabViewItem

import Foundation
import ObjectiveC

extension NSTabViewItem {
    private struct AssociatedKeys {
        static var vc = "viewController"
    }
    
    var vc: NSViewController? {
        get {
            guard let vc = objc_getAssociatedObject(self, &AssociatedKeys.vc) as? NSViewController else {
                return nil
            }
            return vc
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociatedKeys.vc, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
