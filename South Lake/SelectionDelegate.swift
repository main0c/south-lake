//
//  SelectionDelegate.swift
//  South Lake
//
//  Created by Philip Dow on 3/28/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

/// Delegate protocol for any kind of object which maintains a selection and
/// wishes to communicate changes in selection. Used in place of selection
/// and selectedObjects bindings because bindings fire when established and do
/// not fire when the same objects are selected again.

protocol SelectionDelegate: class {
    func object(object: AnyObject, didChangeSelection selection: [AnyObject])
}