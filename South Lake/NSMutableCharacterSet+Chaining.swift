//
//  NSMutableCharacterSet+Chaining.swift
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSMutableCharacterSet {
    
    func union(otherSet: NSCharacterSet) -> NSMutableCharacterSet {
        formUnionWithCharacterSet(otherSet)
        return self
    }
    
    func intersection(otherSet: NSCharacterSet) -> NSMutableCharacterSet {
        formIntersectionWithCharacterSet(otherSet)
        return self
    }
}