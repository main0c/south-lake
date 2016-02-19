//
//  NSOutlineView+Selection.swift
//  South Lake
//
//  Created by Philip Dow on 2/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSOutlineView {
    var selectedObjects: [AnyObject] {
        var array: [AnyObject] = []
        for index in selectedRowIndexes {
            guard let item = itemAtRow(index) else {
                continue
            }
            if item is NSTreeNode {
                array.append((item as! NSTreeNode).representedObject!)
            } else {
                array.append(item)
            }
        }
        return array
    }
}